// Updated SettlementService
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../DatabaseHelper/hive_services.dart';
import '../../modelClass/models.dart';
import '../dashboard/controller/dashboard_controller.dart';
import '../dashboard/controller/friendsPage_controller.dart';
import '../dashboard/services/activityPage_services.dart';
import '../expense/controller/expense_controller.dart';

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

      // Update member balances in Hive
      await _updateMemberBalances(
        payer: payer,
        receiver: receiver,
        amount: amount,
      );

      // Save the settlement
      final box = Hive.box<Settlement>(ExpenseManagerService.settlementBoxName);
      await box.add(settlement);
      await ActivityService.logSettlement(
          payer,
          receiver,
          amount,
          groups.isNotEmpty ? groups : null
      );

      return settlement;
    } catch (e) {
      print('Error in recordSettlement: $e');
      rethrow;
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




  static Future<void> _updateExpenseSplits(Settlement settlement) async {
    try {
      for (var expenseSettlement in settlement.expenseSettlements) {
        final expense = expenseSettlement.expense;
        final settledAmount = expenseSettlement.settledAmount;

        // Find and update relevant splits
        ExpenseSplit? payerSplit = _findSplit(expense.splits, settlement.payer.phone);
        ExpenseSplit? receiverSplit = _findSplit(expense.splits, settlement.receiver.phone);

        bool needsUpdate = false;

        if (expense.paidByMember.phone == settlement.receiver.phone) {
          // Receiver paid initially, payer is settling their debt
          if (payerSplit != null) {
            payerSplit.amount = (payerSplit.amount - settledAmount).roundToDouble();
            if (payerSplit.amount < 0) payerSplit.amount = 0;
            needsUpdate = true;
          }
        } else if (expense.paidByMember.phone == settlement.payer.phone) {
          // Payer paid initially, receiver is receiving their share
          if (receiverSplit != null) {
            receiverSplit.amount = (receiverSplit.amount - settledAmount).roundToDouble();
            if (receiverSplit.amount < 0) receiverSplit.amount = 0;
            needsUpdate = true;
          }
        }

        if (needsUpdate) {
          // Use the helper method to safely update the expense
          await _safelyUpdateExpense(expense);
        }
      }
    } catch (e) {
      print('Error updating expense splits: $e');
      rethrow;
    }
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
      // Step 1: Record the settlement
      final settlement = await recordSettlement(
        payer: payer,
        receiver: receiver,
        amount: amount,
        groups: groups,
      );

      // Step 2: Update expense splits
      await _updateExpenseSplits(settlement);

      // Step 3: Update group balances
     // await _updateGroupBalances(settlement);

      await ActivityService.logSettlement(
          payer,
          receiver,
          amount,
          groups.isNotEmpty ? groups : null
      );


      // Step 4: Update UI components
      await _updateUIComponents();

      return settlement;
    } catch (e) {
      print('Error in recordAndUpdateSettlement: $e');
      rethrow;
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
    // Group settlements by group
    Map<int?, double> settledAmountsByGroup = {};

    for (var settlement in settlements) {
      final groupId = settlement.expense.group?.id;
      if (groupId != null) {
        settledAmountsByGroup[groupId] = (settledAmountsByGroup[groupId] ?? 0) +
            settlement.settledAmount;
      }
    }

    // Update each group's balances
    for (var entry in settledAmountsByGroup.entries) {
      final group = ExpenseManagerService.getGroupById(entry.key!);
      if (group != null) {
        // Recalculate and update member balances within the group
        for (var member in group.members) {
          final balance = group.getMemberBalance(member);
          if (member.phone == payer.phone || member.phone == receiver.phone) {
            final membersBox = Hive.box<Member>(ExpenseManagerService.memberBoxName);
            final memberInBox = membersBox.get(member.phone);
            if (memberInBox != null) {
              memberInBox.totalAmountOwedByMe = balance < 0 ? -balance : 0;
              await memberInBox.save();
            }
          }
        }
        // Update the group itself
        await ExpenseManagerService.updateGroup(group);
      }
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