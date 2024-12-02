// settlement_service.dart

import 'package:hive/hive.dart';
import '../../DatabaseHelper/hive_services.dart';
import '../../modelClass/models.dart';
// settlement_service.dart


class SettlementService {
  /// Records a settlement between two members
  static Future<Settlement> recordSettlement({
    required Member payer,
    required Member receiver,
    required double amount,
    required List<Group> groups,
  }) async {
    // Step 1: Get all unsettled expenses involving both members from specified groups
    List<Expense> unsettledExpenses = _getUnsettledExpenses(
      payer: payer,
      receiver: receiver,
      groups: groups,
    );

    // Step 2: Sort expenses by creation date (oldest first)
    unsettledExpenses.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Step 3: Process the settlement
    final settlementResult = await _processSettlement(
      payer: payer,
      receiver: receiver,
      amount: amount,
      expenses: unsettledExpenses,
    );

    // Step 4: Create and save the settlement record
    final settlement = Settlement(
      payer: payer,
      receiver: receiver,
      amount: amount,
      expenseSettlements: settlementResult.expenseSettlements,
    );

    // Save the settlement
    final box = Hive.box<Settlement>('settlements');
    await box.add(settlement);

    return settlement;
  }

  /// Get all unsettled expenses involving both members from specified groups
  static List<Expense> _getUnsettledExpenses({
    required Member payer,
    required Member receiver,
    required List<Group> groups,
  }) {
    List<Expense> relevantExpenses = [];

    for (var group in groups) {
      final expenses = ExpenseManagerService.getExpensesByGroup(group);

      for (var expense in expenses) {
        // Check if both members are involved in this expense
        bool isPayerInvolved = expense.paidByMember.phone == payer.phone ||
            expense.splits.any((split) => split.member.phone == payer.phone);

        bool isReceiverInvolved = expense.paidByMember.phone == receiver.phone ||
            expense.splits.any((split) => split.member.phone == receiver.phone);

        if (isPayerInvolved && isReceiverInvolved) {
          // Calculate remaining unsettled amount for this expense
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

  /// Calculate the unsettled amount between payer and receiver for an expense
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

  /// Helper method to find split for a member
  static ExpenseSplit? _findSplit(List<ExpenseSplit> splits, String phone) {
    try {
      return splits.firstWhere((split) => split.member.phone == phone);
    } catch (e) {
      return null;
    }
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

    // Sort expenses by smallest unsettled amount first
    expenses.sort((a, b) {
      double amountA = _calculateUnsettledAmount(
        expense: a,
        payer: payer,
        receiver: receiver,
      );
      double amountB = _calculateUnsettledAmount(
        expense: b,
        payer: payer,
        receiver: receiver,
      );
      return amountA.compareTo(amountB);
    });

    for (var expense in expenses) {
      if (remainingAmount <= 0) break;

      double unsettledAmount = _calculateUnsettledAmount(
        expense: expense,
        payer: payer,
        receiver: receiver,
      );

      if (unsettledAmount <= 0) continue;

      // Determine how much of this expense can be settled
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

      // Update expense splits to reflect settlement
      await _updateExpenseSplits(
        expense: expense,
        payer: payer,
        receiver: receiver,
        settledAmount: settleAmount,
      );

      remainingAmount -= settleAmount;
    }

    return SettlementResult(
      expenseSettlements: expenseSettlements,
      remainingAmount: remainingAmount,
    );
  }

  /// Update expense splits to reflect the settlement
  static Future<void> _updateExpenseSplits({
    required Expense expense,
    required Member payer,
    required Member receiver,
    required double settledAmount,
  }) async {
    // Update splits based on who paid the expense
    if (expense.paidByMember.phone == receiver.phone) {
      // Receiver paid, updating payer's split
      final payerSplit = _findSplit(expense.splits, payer.phone);
      if (payerSplit != null) {
        payerSplit.amount -= settledAmount;
        await expense.save();
      }
    } else if (expense.paidByMember.phone == payer.phone) {
      // Payer paid, updating receiver's split
      final receiverSplit = _findSplit(expense.splits, receiver.phone);
      if (receiverSplit != null) {
        receiverSplit.amount -= settledAmount;
        await expense.save();
      }
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