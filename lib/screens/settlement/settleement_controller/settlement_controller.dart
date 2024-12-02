import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../../DatabaseHelper/hive_services.dart';
import '../../../modelClass/models.dart';
import '../../dashboard/controller/dashboard_controller.dart';
import '../../dashboard/controller/friendsPage_controller.dart';
// Updated SettlementController

class SettlementController extends GetxController {
  final RxList<SettlementTransaction> settlements = <SettlementTransaction>[].obs;
  final RxBool isCalculating = false.obs;
  final RxList<Map<String, dynamic>> groupBalances = <Map<String, dynamic>>[].obs;

  // Calculate settlements for a group
  List<SettlementTransaction> calculateSettlements(Group group) {
    List<SettlementTransaction> transactions = [];
    Map<String, double> balances = {};

    // Calculate net balances for each member
    for (var member in group.members) {
      double balance = ExpenseManagerService.getGroupBalance(group, member);
      if (balance != 0) {
        balances[member.phone] = balance;
      }
    }

    // Calculate settlements
    while (balances.isNotEmpty) {
      var debtors = balances.entries.where((e) => e.value < 0).toList();
      var creditors = balances.entries.where((e) => e.value > 0).toList();

      if (debtors.isEmpty || creditors.isEmpty) break;

      var maxDebtor = debtors.reduce((a, b) => a.value < b.value ? a : b);
      var maxCreditor = creditors.reduce((a, b) => a.value > b.value ? a : b);

      double settlementAmount = maxDebtor.value.abs() < maxCreditor.value
          ? maxDebtor.value.abs()
          : maxCreditor.value;

      transactions.add(SettlementTransaction(
        payer: group.members.firstWhere((m) => m.phone == maxDebtor.key),
        receiver: group.members.firstWhere((m) => m.phone == maxCreditor.key),
        amount: settlementAmount,
      ));

      if (maxDebtor.value.abs() == settlementAmount) {
        balances.remove(maxDebtor.key);
        balances[maxCreditor.key] = maxCreditor.value - settlementAmount;
        if (balances[maxCreditor.key] == 0) {
          balances.remove(maxCreditor.key);
        }
      } else {
        balances.remove(maxCreditor.key);
        balances[maxDebtor.key] = maxDebtor.value + settlementAmount;
        if (balances[maxDebtor.key] == 0) {
          balances.remove(maxDebtor.key);
        }
      }
    }

    settlements.value = transactions;
    return transactions;
  }

  // Record a settlement
  Future<void> recordSettlement({
    required Member payer,
    required Member receiver,
    required double amount,
    required Group group,
  }) async {
    try {
      // Create new settlement record with expense settlements
      List<ExpenseSettlement> expenseSettlements = [];
      double remainingAmount = amount;

      // Get relevant expenses for this settlement
      final groupExpenses = ExpenseManagerService.getExpensesByGroup(group);

      for (var expense in groupExpenses) {
        if (remainingAmount <= 0) break;

        // Check if this expense is relevant for the settlement
        if (expense.paidByMember.phone == receiver.phone) {
          final payerSplit = expense.splits.firstWhereOrNull(
                (split) => split.member.phone == payer.phone,
          );

          if (payerSplit != null) {
            final settlementAmount = remainingAmount > payerSplit.amount
                ? payerSplit.amount
                : remainingAmount;

            expenseSettlements.add(
              ExpenseSettlement(
                expense: expense,
                settledAmount: settlementAmount,
              ),
            );

            remainingAmount -= settlementAmount;

            // Update the split amount in the expense
            await ExpenseManagerService.settleExpense(
              expense,
              payer,
              receiver,
              settlementAmount,
            );
          }
        }
      }

      // Create and save the settlement record
      final settlement = Settlement(
        payer: payer,
        receiver: receiver,
        amount: amount - remainingAmount,
        expenseSettlements: expenseSettlements,
      );

      final box = Hive.box<Settlement>(ExpenseManagerService.settlementBoxName);
      await box.add(settlement);

      // Update UI
      _updateUIAfterSettlement(group);

      Get.snackbar(
        'Success',
        'Settlement recorded successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to record settlement: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Update UI after settlement
  void _updateUIAfterSettlement(Group group) {
    try {
      // Update Dashboard if it exists
      try {
        final dashboardController = Get.find<DashboardController>();
        dashboardController.loadGroups();
        dashboardController.getBalanceText();
      } catch (_) {}

      // Update Friends page if it exists
      try {
        final friendsController = Get.find<FriendsController>();
        friendsController.loadMembers();
      } catch (_) {}

      // Recalculate settlements for the current group
      calculateSettlements(group);

      // Refresh group balances
      if (groupBalances.isNotEmpty) {
        final updatedBalances = group.members.map((member) {
          return {
            'member': member,
            'balance': ExpenseManagerService.getGroupBalance(group, member),
            'isSettled': false,
          };
        }).toList();
        groupBalances.value = updatedBalances;
      }

    } catch (e) {
      print('Error updating UI after settlement: $e');
    }
  }
}