import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../DatabaseHelper/hive_services.dart';
import '../../modelClass/models.dart';
import '../dashboard/services/activityPage_services.dart';

class SettlementHandler {
  /// Processes a settlement between members
  static Future<void> processSettlement({
    required Member payer,
    required Member receiver,
    required double amount,
    required List<Group> selectedGroups,
  }) async {
    try {
      // Get all unsettled expenses involving these members in selected groups
      List<Expense> relevantExpenses = [];
      for (var group in selectedGroups) {
        final expenses = ExpenseManagerService.getExpensesByGroup(group)
            .where((e) => e.status != ExpenseStatus.fullySettled &&
            (e.paidByMember.phone == receiver.phone ||
                e.paidByMember.phone == payer.phone))
            .toList();
        relevantExpenses.addAll(expenses);
      }

      // Sort expenses by date (oldest first)
      relevantExpenses.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      double remainingAmount = amount;
      List<ExpenseSettlement> expenseSettlements = [];

      // Process each expense
      for (var expense in relevantExpenses) {
        if (remainingAmount <= 0) break;

        // Skip if expense is not from receiver to payer
        if (expense.paidByMember.phone != receiver.phone) continue;

        // Find payer's split
        final payerSplit = expense.splits.firstWhere(
              (split) => split.member.phone == payer.phone,
          orElse: () => ExpenseSplit(member: payer, amount: 0),
        );

        if (payerSplit.amount <= 0) continue;

        // Calculate settlement amount for this expense
        double settleAmount = payerSplit.amount <= remainingAmount
            ? payerSplit.amount
            : remainingAmount;

        // Create settlement record for this expense
        expenseSettlements.add(ExpenseSettlement(
          expense: expense,
          settledAmount: settleAmount,
        ));

        // Update the split
        payerSplit.amount -= settleAmount;
        remainingAmount -= settleAmount;

        // Update expense status
        if (expense.splits.every((split) => split.amount <= 0.01)) {
          expense.status = ExpenseStatus.fullySettled;
        } else {
          expense.status = ExpenseStatus.partiallySettled;
        }

        // Save expense changes
        await expense.save();
      }

      if (expenseSettlements.isEmpty) {
        throw Exception('No valid expenses found for settlement');
      }

      // Create settlement record
      final settlement = Settlement(
        payer: payer,
        receiver: receiver,
        amount: amount - remainingAmount,
        expenseSettlements: expenseSettlements,
        status: remainingAmount > 0 ? 'partial' : 'complete',
        remainingAmount: remainingAmount,
      );

      // Save settlement
      final settlementBox = Hive.box<Settlement>(ExpenseManagerService.settlementBoxName);
      await settlementBox.add(settlement);

      // Update member balances
      await ExpenseManagerService.recalculateAllBalances();

    } catch (e) {
      print('Settlement error: $e');
      rethrow;
    }
  }


  static List<Expense> _getRelevantExpenses({
    required Member currentUser,
    required Member otherMember,
    required List<Group> groups,
  }) {
    List<Expense> relevantExpenses = [];

    for (var group in groups) {
      final expenses = ExpenseManagerService.getExpensesByGroup(group)
          .where((e) =>
      e.status != ExpenseStatus.fullySettled && // Exclude fully settled expenses
          _isMemberInvolved(e, currentUser, otherMember))
          .toList();

      relevantExpenses.addAll(expenses);
    }

    return relevantExpenses;
  }

  static bool _isMemberInvolved(Expense expense, Member currentUser, Member otherMember) {
    return expense.paidByMember.phone == currentUser.phone ||
        expense.paidByMember.phone == otherMember.phone ||
        expense.splits.any((split) => split.member.phone == currentUser.phone ||
            split.member.phone == otherMember.phone);
  }


  static Future<double> _processExpenseSettlement({
    required Expense expense,
    required Member currentUser,
    required Member otherMember,
    required double remainingAmount,
  }) async {
    try {
      final expenseBox = Hive.box<Expense>(ExpenseManagerService.expenseBoxName);

      // Get fresh copy of expense
      final freshExpense = expenseBox.get(expense.key) ?? expense;

      ExpenseSplit? relevantSplit = _findRelevantSplit(freshExpense, currentUser, otherMember);

      if (relevantSplit == null || relevantSplit.amount <= 0) {
        return 0;
      }

      double settleAmount = relevantSplit.amount <= remainingAmount
          ? relevantSplit.amount
          : remainingAmount;

      relevantSplit.amount = (relevantSplit.amount - settleAmount).roundToDouble();

      // Update expense status
      bool isFullySettled = freshExpense.splits.every((split) =>
      split.amount <= 0.01 || split.member.phone == freshExpense.paidByMember.phone);

      freshExpense.status = isFullySettled
          ? ExpenseStatus.fullySettled
          : ExpenseStatus.partiallySettled;

      // Save the updated expense atomically
      await expenseBox.put(expense.key, freshExpense);

      return settleAmount;
    } catch (e) {
      print('Error processing expense settlement: $e');
      throw Exception('Failed to process expense settlement: ${e.toString()}');
    }
  }

  static ExpenseSplit? _findRelevantSplit(
      Expense expense,
      Member currentUser,
      Member otherMember
      ) {
    // If current user is the payer, look for other member's split
    if (expense.paidByMember.phone == currentUser.phone) {
      return expense.splits.firstWhereOrNull(
              (split) => split.member.phone == otherMember.phone
      );
    }
    // If other member is the payer, look for current user's split
    else if (expense.paidByMember.phone == otherMember.phone) {
      return expense.splits.firstWhereOrNull(
              (split) => split.member.phone == currentUser.phone
      );
    }
    return null;
  }


  static Future<void> _recordTransaction({
    required Member payer,
    required Member receiver,
    required double amount,
  }) async {
    final transaction = Transaction(
      type: 'settlement',
      amount: amount,
      payer: payer,
      receiver: receiver,
      timestamp: DateTime.now(),
      description: 'Settlement payment',
    );

    final transactionBox = Hive.box<Transaction>(ExpenseManagerService.transactionBoxName);
    await transactionBox.add(transaction);
  }
}

class SettlementVerifier {
  static void verifySettlement({
    required Group group,
    required Member currentUser,
    required List<Expense> expenses,
    required List<Settlement> settlements,
  }) {
    print('\n=== Settlement Verification ===');

    // Verify individual expenses
    for (var expense in expenses) {
      print('\nExpense: ${expense.description}');
      print('Total Amount: ₹${expense.totalAmount}');

      if (expense.paidByMember.phone == currentUser.phone) {
        double totalLent = expense.splits
            .where((split) => split.member.phone != currentUser.phone)
            .fold(0.0, (sum, split) => sum + split.amount);
        print('Amount Lent: ₹$totalLent');
      } else {
        var myShare = expense.splits
            .firstWhere((split) => split.member.phone == currentUser.phone)
            .amount;
        print('Amount Owed to ${expense.paidByMember.name}: ₹$myShare');
      }
    }

    // Verify settlements
    print('\nSettlements:');
    for (var settlement in settlements) {
      print('- ${settlement.payer.name} paid ${settlement.receiver.name}: ₹${settlement.amount}');
    }

    // Verify final balances
    // final balance = ExpenseManagerService.calculateGroupBalance(group, currentUser);
    final balances = ExpenseManagerService.calculateGroupBalance(group, currentUser);

    if ((balances.amountToReceive - balances.amountToPayBack).abs() > 0.01) {
      print('Warning: Discrepancy in final net balance calculations');
    } else {
      print('Balances verified successfully!');
    }
    // print('\nFinal Balance:');
    // print('Amount to Receive: ₹${balance.amountToReceive}');
    // print('Amount to Pay Back: ₹${balance.amountToPayBack}');
    // print('Net Amount: ₹${balance.netAmount}');
    print('==============================\n');
  }
}