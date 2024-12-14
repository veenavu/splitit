// Updated SettlementService
import 'dart:math';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../DatabaseHelper/hive_services.dart';
import '../../modelClass/models.dart';
import '../dashboard/controller/dashboard_controller.dart';
import '../dashboard/controller/friendsPage_controller.dart';
import '../dashboard/services/activityPage_services.dart';

class SettlementService {

  static Future<Settlement> recordSettlement({
    required Member payer,
    required Member receiver,
    required double amount,
    required List<Group> groups,
  }) async {
    try {
      // Get unsettled expenses
      List<Expense> unsettledExpenses = _getUnsettledExpenses(
        payer: payer,
        receiver: receiver,
        groups: groups,
      );

      // Sort expenses by date
      unsettledExpenses.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Process the settlement
      final settlementResult = await _processSettlement(
        payer: payer,
        receiver: receiver,
        amount: amount,
        expenses: unsettledExpenses,
      );

      // Create settlement record
      final settlement = Settlement(
        payer: payer,
        receiver: receiver,
        amount: amount,
        expenseSettlements: settlementResult.expenseSettlements,
      );

      // Update member balances in groups
      await _processGroupSettlement(
        payer,
        receiver,
        amount,
        groups,
      );

      // Save the settlement
      final box = Hive.box<Settlement>(ExpenseManagerService.settlementBoxName);
      await box.add(settlement);

      // Log the settlement
      await ActivityService.logSettlement(
        payer,
        receiver,
        amount,
        groups.isNotEmpty ? groups : null,
      );

      return settlement;
    } catch (e) {
      print('Error in recordSettlement: $e');
      rethrow;
    }
  }


  static Future<void> _processGroupSettlement(
      Member payer,
      Member receiver,
      double amount,
      List<Group> groups,
      ) async {
    final Map<String, double> groupSettlements = {};
    double remainingAmount = amount;

    // First pass: Calculate how much to settle in each group
    for (var group in groups) {
      if (remainingAmount <= 0) break;

      // Calculate unsettled amount in this group
      double groupUnsettledAmount = 0;
      final expenses = ExpenseManagerService.getExpensesByGroup(group);

      for (var expense in expenses) {
        groupUnsettledAmount += _calculateUnsettledAmount(
          expense: expense,
          payer: payer,
          receiver: receiver,
        );
      }

      if (groupUnsettledAmount > 0) {
        double groupSettleAmount = remainingAmount >= groupUnsettledAmount
            ? groupUnsettledAmount
            : remainingAmount;

        groupSettlements[group.id.toString()] = groupSettleAmount;
        remainingAmount -= groupSettleAmount;
      }
    }

    // Second pass: Apply settlements to each group
    for (var entry in groupSettlements.entries) {
      final group = ExpenseManagerService.getGroupById(int.parse(entry.key));
      if (group != null) {
        final settleAmount = entry.value;

        // Update member balances in the group
        final membersBox = Hive.box<Member>(ExpenseManagerService.memberBoxName);

        // Update payer's group balance
        final payerMember = membersBox.get(payer.phone);
        if (payerMember != null) {
          payerMember.balancesByGroup[entry.key] =
              (payerMember.balancesByGroup[entry.key] ?? 0) - settleAmount;
          await payerMember.save();
        }

        // Update receiver's group balance
        final receiverMember = membersBox.get(receiver.phone);
        if (receiverMember != null) {
          receiverMember.balancesByGroup[entry.key] =
              (receiverMember.balancesByGroup[entry.key] ?? 0) + settleAmount;
          await receiverMember.save();
        }
      }
    }
  }


  static Future<void> _updateMemberBalances({
    required Member payer,
    required Member receiver,
    required double amount,
  }) async {
    final membersBox = Hive.box<Member>(ExpenseManagerService.memberBoxName);

    // Update payer's balance
    final payerInBox = membersBox.get(payer.phone);
    if (payerInBox != null) {
      payerInBox.totalAmountOwedByMe = (payerInBox.totalAmountOwedByMe - amount).roundToDouble();
      if (payerInBox.totalAmountOwedByMe < 0) payerInBox.totalAmountOwedByMe = 0;
      await payerInBox.save();
    }

    // Update receiver's balance
    final receiverInBox = membersBox.get(receiver.phone);
    if (receiverInBox != null) {
      receiverInBox.totalAmountOwedByMe = (receiverInBox.totalAmountOwedByMe + amount).roundToDouble();
      await receiverInBox.save();
    }
  }

  static Future<void> _safelyUpdateExpense(Expense expense) async {
    final box = Hive.box<Expense>(ExpenseManagerService.expenseBoxName);

    // Find the expense index in the box
    int? index;
    for (int i = 0; i < box.length; i++) {
      if (box.getAt(i)?.id == expense.id) {
        index = i;
        break;
      }
    }

    if (index != null) {
      await box.putAt(index, expense);
    } else {
      throw Exception('Expense not found in box: ${expense.id}');
    }
  }

  static Future<SettlementResult> _processSettlement({
    required Member payer,
    required Member receiver,
    required double amount,
    required List<Expense> expenses,
  }) async {
    double remainingAmount = amount;
    List<ExpenseSettlement> expenseSettlements = [];

    for (var expense in expenses) {
      if (remainingAmount <= 0) break;

      double unsettledAmount = _calculateUnsettledAmount(
        expense: expense,
        payer: payer,
        receiver: receiver,
      );

      if (unsettledAmount <= 0) continue;

      double settleAmount = unsettledAmount <= remainingAmount
          ? unsettledAmount
          : remainingAmount;

      // Create settlement record for this expense
      expenseSettlements.add(
        ExpenseSettlement(
          expense: expense,
          settledAmount: settleAmount,
        ),
      );

      // Update expense splits
      if (expense.paidByMember.phone == receiver.phone) {
        var payerSplit = _findSplit(expense.splits, payer.phone);
        if (payerSplit != null) {
          payerSplit.amount = (payerSplit.amount - settleAmount).roundToDouble();
          if (payerSplit.amount < 0) payerSplit.amount = 0;
          await _safelyUpdateExpense(expense);
        }
      } else if (expense.paidByMember.phone == payer.phone) {
        var receiverSplit = _findSplit(expense.splits, receiver.phone);
        if (receiverSplit != null) {
          receiverSplit.amount = (receiverSplit.amount - settleAmount).roundToDouble();
          if (receiverSplit.amount < 0) receiverSplit.amount = 0;
          await _safelyUpdateExpense(expense);
        }
      }

      remainingAmount -= settleAmount;
    }

    // Update group balances
    await _updateGroupBalances(payer, receiver, expenseSettlements);

    return SettlementResult(
      expenseSettlements: expenseSettlements,
      remainingAmount: remainingAmount,
    );
  }






  /// Process the settlement and return settlement details



  /// Records a settlement and updates all relevant UI components

  static Future<Settlement> recordAndUpdateSettlement({
    required Member payer,
    required Member receiver,
    required double amount,
    required List<Group> groups,
  }) async {
    try {
      // Step 1: Get unsettled expenses
      List<Expense> unsettledExpenses = _getUnsettledExpenses(
        payer: payer,
        receiver: receiver,
        groups: groups,
      );

      double totalUnsettledAmount = 0.0;
      // Calculate total unsettled amount
      for (var expense in unsettledExpenses) {
        totalUnsettledAmount += _calculateUnsettledAmount(
          expense: expense,
          payer: payer,
          receiver: receiver,
        );
      }

      // Step 2: Record the settlement
      final settlement = await recordSettlement(
        payer: payer,
        receiver: receiver,
        amount: amount,
        groups: groups,
      );

      // Step 3: Update member balances in Hive
      final membersBox = Hive.box<Member>(ExpenseManagerService.memberBoxName);

      // Update payer's balance
      final payerMember = membersBox.get(payer.phone);
      if (payerMember != null) {
        // Only subtract the settled amount, keeping any remaining balance
        double newBalance = payerMember.totalAmountOwedByMe - amount;
        payerMember.totalAmountOwedByMe = newBalance < 0 ? 0 : newBalance;
        await payerMember.save();
      }

      // Update receiver's balance
      final receiverMember = membersBox.get(receiver.phone);
      if (receiverMember != null) {
        double newBalance = receiverMember.totalAmountOwedByMe + amount;
        receiverMember.totalAmountOwedByMe = newBalance;
        await receiverMember.save();
      }

      // Step 4: Update expense splits
      await _updateExpenseSplits(settlement);

      // Step 5: Update group balances
      await _updateGroupBalances(payer, receiver, settlement.expenseSettlements);

      await ActivityService.logSettlement(
          payer,
          receiver,
          amount,
          groups.isNotEmpty ? groups : null
      );

      // Step 6: Update UI components
      await _updateUIComponents();

      return settlement;
    } catch (e) {
      print('Error in recordAndUpdateSettlement: $e');
      rethrow;
    }
  }

  static Future<void> recordPartialSettlement({
    required Member payer,
    required Member receiver,
    required double amount,
    required double totalOwedAmount,
    required List<Group> groups,
  }) async {
    try {
      final box = Hive.box<Member>(ExpenseManagerService.memberBoxName);

      // Calculate remaining amount after settlement
      double remainingAmount = totalOwedAmount - amount;

      // Update payer's balance
      final payerMember = box.get(payer.phone);
      if (payerMember != null) {
        payerMember.totalAmountOwedByMe = remainingAmount;
        await payerMember.save();
      }

      // Process group-wise settlements
      double remainingSettlement = amount;
      for (var group in groups) {
        if (remainingSettlement <= 0) break;

        // Get unsettled expenses for this group
        final expenses = ExpenseManagerService.getExpensesByGroup(group)
            .where((expense) => !expense.splits.every((split) => split.amount == 0))
            .toList();

        for (var expense in expenses) {
          if (remainingSettlement <= 0) break;

          // Find relevant splits
          var payerSplit = expense.splits
              .firstWhereOrNull((split) => split.member.phone == payer.phone);
          var receiverSplit = expense.splits
              .firstWhereOrNull((split) => split.member.phone == receiver.phone);

          if (payerSplit != null && payerSplit.amount > 0) {
            double settleAmount = min(payerSplit.amount, remainingSettlement);
            payerSplit.amount -= settleAmount;
            remainingSettlement -= settleAmount;

            // Create settlement record
            final settlement = Settlement(
              payer: payer,
              receiver: receiver,
              amount: settleAmount,
              expenseSettlements: [
                ExpenseSettlement(
                  expense: expense,
                  settledAmount: settleAmount,
                )
              ],
              status: remainingAmount > 0 ? 'partial' : 'complete',
              remainingAmount: remainingAmount,
            );

            // Save settlement
            final settlementBox = Hive.box<Settlement>(ExpenseManagerService.settlementBoxName);
            await settlementBox.add(settlement);

            // Save expense updates
            await expense.save();
          }
        }
      }

      // Create activity log
      await ActivityService.logSettlement(
        payer,
        receiver,
        amount,
        groups.isNotEmpty ? groups : null,
      );

    } catch (e) {
      print('Error in recordPartialSettlement: $e');
      rethrow;
    }
  }





// Update the _updateExpenseSplits method to handle partial settlements
  static Future<void> _updateExpenseSplits(Settlement settlement) async {
    try {
      double remainingSettlementAmount = settlement.amount;

      for (var expenseSettlement in settlement.expenseSettlements) {
        if (remainingSettlementAmount <= 0) break;

        final expense = expenseSettlement.expense;
        final currentSettlementAmount = expenseSettlement.settledAmount;

        // Find and update relevant splits
        ExpenseSplit? payerSplit = _findSplit(expense.splits, settlement.payer.phone);
        ExpenseSplit? receiverSplit = _findSplit(expense.splits, settlement.receiver.phone);

        bool needsUpdate = false;

        if (expense.paidByMember.phone == settlement.receiver.phone && payerSplit != null) {
          // Calculate new amount after partial settlement
          double newAmount = payerSplit.amount - currentSettlementAmount;
          payerSplit.amount = newAmount < 0 ? 0 : newAmount;
          needsUpdate = true;
        } else if (expense.paidByMember.phone == settlement.payer.phone && receiverSplit != null) {
          // Calculate new amount after partial settlement
          double newAmount = receiverSplit.amount - currentSettlementAmount;
          receiverSplit.amount = newAmount < 0 ? 0 : newAmount;
          needsUpdate = true;
        }

        if (needsUpdate) {
          await _safelyUpdateExpense(expense);
        }

        remainingSettlementAmount -= currentSettlementAmount;
      }
    } catch (e) {
      print('Error updating expense splits: $e');
      rethrow;
    }
  }

  // Helper method to update member balances in groups for partial settlements
  static Future<void> _updateBalancesForPartialSettlement(
      Member payer,
      Member receiver,
      double amount,
      double totalOwed,
      ) async {
    final membersBox = Hive.box<Member>(ExpenseManagerService.memberBoxName);

    // Update payer's balance
    final payerMember = membersBox.get(payer.phone);
    if (payerMember != null) {
      double remainingBalance = totalOwed - amount;
      payerMember.totalAmountOwedByMe = remainingBalance < 0 ? 0 : remainingBalance;
      await payerMember.save();
    }

    // Update receiver's balance
    final receiverMember = membersBox.get(receiver.phone);
    if (receiverMember != null) {
      receiverMember.totalAmountOwedByMe += amount;
      await receiverMember.save();
    }
  }





  static ExpenseSplit? _findSplit(List<ExpenseSplit> splits, String phone) {
    try {
      return splits.firstWhere((split) => split.member.phone == phone);
    } catch (e) {
      return null;
    }
  }
  /// Records a basic settlement between two members


  /// Get unsettled expenses between members
  static List<Expense> _getUnsettledExpenses({
    required Member payer,
    required Member receiver,
    required List<Group> groups,
  }) {
    List<Expense> relevantExpenses = [];

    for (var group in groups) {
      final expenses = ExpenseManagerService.getExpensesByGroup(group);

      for (var expense in expenses) {
        bool isPayerInvolved = expense.paidByMember.phone == payer.phone ||
            expense.splits.any((split) => split.member.phone == payer.phone);

        bool isReceiverInvolved = expense.paidByMember.phone == receiver.phone ||
            expense.splits.any((split) => split.member.phone == receiver.phone);

        if (isPayerInvolved && isReceiverInvolved) {
          double unsettledAmount = _calculateUnsettledAmount(
            expense: expense,
            payer: payer,
            receiver: receiver,
          );

          if (unsettledAmount > 0) {
            relevantExpenses.add(expense);
          }
        }
      }
    }

    return relevantExpenses;
  }


  static Future<void> _updateGroupBalances(
      Member payer,
      Member receiver,
      List<ExpenseSettlement> settlements,
      ) async {
    final membersBox = Hive.box<Member>(ExpenseManagerService.memberBoxName);

    // Group settlements by group
    Map<Group, double> settledAmountsByGroup = {};

    // Calculate settled amounts for each group
    for (var settlement in settlements) {
      final expense = settlement.expense;
      if (expense.group != null) {
        settledAmountsByGroup[expense.group!] =
            (settledAmountsByGroup[expense.group!] ?? 0) + settlement.settledAmount;
      }
    }

    // Update each group's member balances
    for (var entry in settledAmountsByGroup.entries) {
      final group = entry.key;
      final settledAmount = entry.value;

      // Update payer's balance in this group
      final payerMember = membersBox.get(payer.phone);
      if (payerMember != null) {
        String groupKey = group.id.toString();
        payerMember.balancesByGroup[groupKey] =
            (payerMember.balancesByGroup[groupKey] ?? 0) - settledAmount;
        await payerMember.save();
      }

      // Update receiver's balance in this group
      final receiverMember = membersBox.get(receiver.phone);
      if (receiverMember != null) {
        String groupKey = group.id.toString();
        receiverMember.balancesByGroup[groupKey] =
            (receiverMember.balancesByGroup[groupKey] ?? 0) + settledAmount;
        await receiverMember.save();
      }

      // Update group itself to reflect new balances
      await ExpenseManagerService.updateGroup(group);
    }
  }



  // In settlement_services.dart

  static Future<void> _updateUIComponents() async {
    try {
      // Update Dashboard
      if (Get.isRegistered<DashboardController>()) {
        final dashboardController = Get.find<DashboardController>();
        await dashboardController.loadGroups();
        dashboardController.getBalanceText();
        dashboardController.update();
      }

      // Update Friends list
      if (Get.isRegistered<FriendsController>()) {
        final friendsController = Get.find<FriendsController>();
        try {
          await friendsController.loadMembers();
        } catch (e) {
          print('Error updating friends list: $e');
          // Handle error but don't rethrow to prevent UI update failure
        }
      }

      // Ensure UI is refreshed
      await Future.delayed(const Duration(milliseconds: 100));
      Get.forceAppUpdate();
    } catch (e) {
      print('Error in _updateUIComponents: $e');
      rethrow;
    }
  }

  /// Calculate unsettled amount between members for an expense
  static double _calculateUnsettledAmount({
    required Expense expense,
    required Member payer,
    required Member receiver,
  }) {
    double amount = 0.0;

    // Case 1: Receiver paid, Payer owes
    if (expense.paidByMember.phone == receiver.phone) {
      final payerSplit = _findSplit(expense.splits, payer.phone);
      if (payerSplit != null) {
        amount += payerSplit.amount;
      }
    }

    // Case 2: Payer paid, Receiver owes
    if (expense.paidByMember.phone == payer.phone) {
      final receiverSplit = _findSplit(expense.splits, receiver.phone);
      if (receiverSplit != null) {
        amount -= receiverSplit.amount;
      }
    }

    return amount.abs();
  }
}

/// Class to hold settlement processing results
class SettlementResult {
  final List<ExpenseSettlement> expenseSettlements;
  final double remainingAmount;

  SettlementResult({
    required this.expenseSettlements,
    required this.remainingAmount,
  });
}