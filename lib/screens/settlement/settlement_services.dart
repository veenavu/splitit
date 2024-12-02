
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../DatabaseHelper/hive_services.dart';
import '../../modelClass/models.dart';

class SettlementService extends GetxService {
  static const String settlementBoxName = 'settlements';

  Future<void> settleExpenses({
    required Member profileOwner,
    required Member otherMember,
    required double settlementAmount,
    List<Expense>? specificExpenses,
  }) async {
    // Get relevant expenses
    final allExpenses = specificExpenses ?? ExpenseManagerService.getAllExpenses();

    // Filter expenses involving both members
    final relevantExpenses = allExpenses.where((expense) {
      final isProfileOwnerPayer = expense.paidByMember.phone == profileOwner.phone;
      final isOtherMemberPayer = expense.paidByMember.phone == otherMember.phone;
      final isProfileOwnerInSplit = expense.splits
          .any((split) => split.member.phone == profileOwner.phone);
      final isOtherMemberInSplit = expense.splits
          .any((split) => split.member.phone == otherMember.phone);

      return (isProfileOwnerPayer && isOtherMemberInSplit) ||
          (isOtherMemberPayer && isProfileOwnerInSplit);
    }).toList();

    double remainingSettlement = settlementAmount;
    List<ExpenseSettlement> expenseSettlements = [];

    // Process expenses where profileOwner is the payer
    for (var expense in relevantExpenses) {
      if (remainingSettlement <= 0) break;

      if (expense.paidByMember.phone == profileOwner.phone) {
        final otherMemberSplit = expense.splits.firstWhere(
              (split) => split.member.phone == otherMember.phone,
          orElse: () => ExpenseSplit(member: otherMember, amount: 0),
        );

        if (otherMemberSplit.amount > 0) {
          final settlementForThisExpense = remainingSettlement > otherMemberSplit.amount
              ? otherMemberSplit.amount
              : remainingSettlement;

          expenseSettlements.add(ExpenseSettlement(
            expense: expense,
            settledAmount: settlementForThisExpense,
          ));

          remainingSettlement -= settlementForThisExpense;
        }
      }
    }

    // Process expenses where otherMember is the payer
    if (remainingSettlement > 0) {
      for (var expense in relevantExpenses) {
        if (remainingSettlement <= 0) break;

        if (expense.paidByMember.phone == otherMember.phone) {
          final profileOwnerSplit = expense.splits.firstWhere(
                (split) => split.member.phone == profileOwner.phone,
            orElse: () => ExpenseSplit(member: profileOwner, amount: 0),
          );

          if (profileOwnerSplit.amount > 0) {
            final settlementForThisExpense = remainingSettlement > profileOwnerSplit.amount
                ? profileOwnerSplit.amount
                : remainingSettlement;

            expenseSettlements.add(ExpenseSettlement(
              expense: expense,
              settledAmount: settlementForThisExpense,
            ));

            remainingSettlement -= settlementForThisExpense;
          }
        }
      }
    }

    // Create and save settlement record
    if (expenseSettlements.isNotEmpty) {
      final settlement = Settlement(
        payer: otherMember,
        receiver: profileOwner,
        amount: settlementAmount - remainingSettlement,
        expenseSettlements: expenseSettlements,
      );

      final box = await Hive.openBox<Settlement>(settlementBoxName);
      await box.add(settlement);

      // Update member balances
      await _updateMemberBalances(settlement);
    }
  }

  Future<void> _updateMemberBalances(Settlement settlement) async {
    final membersBox = Hive.box<Member>(ExpenseManagerService.memberBoxName);

    // Update payer's balance
    final payer = membersBox.get(settlement.payer.phone);
    if (payer != null) {
      payer.totalAmountOwedByMe -= settlement.amount;
      await payer.save();
    }

    // Update receiver's balance
    final receiver = membersBox.get(settlement.receiver.phone);
    if (receiver != null) {
      receiver.totalAmountOwedByMe += settlement.amount;
      await receiver.save();
    }
  }

  List<Settlement> getSettlementsByMember(Member member) {
    final box = Hive.box<Settlement>(settlementBoxName);
    return box.values.where((settlement) =>
    settlement.payer.phone == member.phone ||
        settlement.receiver.phone == member.phone
    ).toList();
  }
}