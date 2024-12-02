// Updated SettlementService
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../DatabaseHelper/hive_services.dart';
import '../../modelClass/models.dart';
import '../dashboard/controller/dashboard_controller.dart';
import '../dashboard/controller/friendsPage_controller.dart';

class SettlementService {
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
      await _updateGroupBalances(settlement);

      // Step 4: Update UI components
      _updateUIComponents();

      return settlement;
    } catch (e) {
      print('Error in recordAndUpdateSettlement: $e');
      rethrow;
    }
  }

  /// Records a basic settlement between two members
  static Future<Settlement> recordSettlement({
    required Member payer,
    required Member receiver,
    required double amount,
    required List<Group> groups,
  }) async {
    // Get all unsettled expenses involving both members from specified groups
    List<Expense> unsettledExpenses = _getUnsettledExpenses(
      payer: payer,
      receiver: receiver,
      groups: groups,
    );

    // Sort expenses by creation date (oldest first)
    unsettledExpenses.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Process the settlement
    final settlementResult = await _processSettlement(
      payer: payer,
      receiver: receiver,
      amount: amount,
      expenses: unsettledExpenses,
    );

    // Create and save the settlement record
    final settlement = Settlement(
      payer: payer,
      receiver: receiver,
      amount: amount,
      expenseSettlements: settlementResult.expenseSettlements,
    );

    // Save the settlement
    final box = Hive.box<Settlement>(ExpenseManagerService.settlementBoxName);
    await box.add(settlement);

    return settlement;
  }

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

  static Future<void> _updateExpenseSplits(Settlement settlement) async {
    for (var expenseSettlement in settlement.expenseSettlements) {
      final expense = expenseSettlement.expense;
      final settledAmount = expenseSettlement.settledAmount;

      // Update the splits based on who paid
      if (expense.paidByMember.phone == settlement.receiver.phone) {
        // Receiver paid, update payer's split
        final payerSplit = _findSplit(expense.splits, settlement.payer.phone);
        if (payerSplit != null) {
          payerSplit.amount -= settledAmount;
          await expense.save();
        }
      } else if (expense.paidByMember.phone == settlement.payer.phone) {
        // Payer paid, update receiver's split
        final receiverSplit = _findSplit(expense.splits, settlement.receiver.phone);
        if (receiverSplit != null) {
          receiverSplit.amount -= settledAmount;
          await expense.save();
        }
      }
    }
  }

  static Future<void> _updateGroupBalances(Settlement settlement) async {
    // Group settlements by group for efficient updates
    Map<int?, double> settledAmountsByGroup = {};

    for (var expenseSettlement in settlement.expenseSettlements) {
      final groupId = expenseSettlement.expense.group?.id;
      if (groupId != null) {
        settledAmountsByGroup[groupId] = (settledAmountsByGroup[groupId] ?? 0) +
            expenseSettlement.settledAmount;
      }
    }

    // Update each affected group
    for (var entry in settledAmountsByGroup.entries) {
      final group = ExpenseManagerService.getGroupById(entry.key!);
      if (group != null) {
        await ExpenseManagerService.updateGroup(group);
      }
    }
  }

  static void _updateUIComponents() {
    try {
      // Update Dashboard text
      final dashboardController = Get.find<DashboardController>();
      dashboardController.getBalanceText();
      dashboardController.loadGroups();
      dashboardController.applyFilter(); // Refresh filtered groups

      // Update Friends list
      if (Get.isRegistered<FriendsController>()) {
        final friendsController = Get.find<FriendsController>();
        friendsController.loadMembers();
      }
    } catch (e) {
      print('Error updating UI components: $e');
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

  /// Process the settlement and return settlement details
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

      expenseSettlements.add(
        ExpenseSettlement(
          expense: expense,
          settledAmount: settleAmount,
        ),
      );

      remainingAmount -= settleAmount;
    }

    return SettlementResult(
      expenseSettlements: expenseSettlements,
      remainingAmount: remainingAmount,
    );
  }

  static ExpenseSplit? _findSplit(List<ExpenseSplit> splits, String phone) {
    try {
      return splits.firstWhere((split) => split.member.phone == phone);
    } catch (e) {
      return null;
    }
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