import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../modelClass/models.dart';
import '../../../DatabaseHelper/hive_services.dart';
import '../../dashboard/controller/dashboard_controller.dart';
import '../../dashboard/controller/friendsPage_controller.dart';

class MemberSettlementController extends GetxController {
  final RxList<Map<String, dynamic>> groupBalances = <Map<String, dynamic>>[].obs;
  final RxDouble customAmount = 0.0.obs;
  final RxBool isCustomAmount = false.obs;
  final Rxn<Profile> currentUser = Rxn<Profile>();

  @override
  void onInit() {
    super.onInit();
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    final box = Hive.box(ExpenseManagerService.normalBox);
    final phone = box.get("mobile");
    currentUser.value = ExpenseManagerService.getProfileByPhone(phone);
  }

  void loadGroupBalances(Member member, bool isUserOwing) {
    if (currentUser.value == null) return;

    groupBalances.clear();
    final allGroups = ExpenseManagerService.getAllGroups();

    // Only include groups where there are actual transactions with the member
    for (var group in allGroups) {
      double balance = _calculateEffectiveGroupBalance(group, member);

      // Only include groups with actual unsettled transactions
      if (balance.abs() > 0.01) {
        groupBalances.add({
          'group': group,
          'balance': balance,
          'isSettled': false,
          'originalBalance': balance,
        });
      }
    }

    // Sort by absolute balance amount (smallest to largest)
    groupBalances.sort((a, b) =>
        (a['balance'] as double).abs().compareTo((b['balance'] as double).abs())
    );
  }

  double _calculateEffectiveGroupBalance(Group group, Member member) {
    double balance = 0.0;
    final expenses = ExpenseManagerService.getExpensesByGroup(group);

    for (var expense in expenses) {
      if (expense.paidByMember.phone == currentUser.value!.phone) {
        // Current user paid, check if member owes
        final memberSplit = expense.splits.firstWhereOrNull(
                (split) => split.member.phone == member.phone
        );
        if (memberSplit != null) {
          balance += memberSplit.amount;
        }
      } else if (expense.paidByMember.phone == member.phone) {
        // Member paid, check if current user owes
        final currentUserSplit = expense.splits.firstWhereOrNull(
                (split) => split.member.phone == currentUser.value!.phone
        );
        if (currentUserSplit != null) {
          balance -= currentUserSplit.amount;
        }
      }
    }

    return balance;
  }

  Future<void> recordSettlement({
    required Member payer,
    required Member receiver,
    required double amount,
    required List<Group> selectedGroups,
  }) async {
    try {
      double remainingAmount = amount;
      List<ExpenseSettlement> expenseSettlements = [];
      List<Map<String, dynamic>> updatedBalances = [];

      // Sort groups by absolute balance amount (smallest to largest)
      groupBalances.sort((a, b) =>
          (a['balance'] as double).abs().compareTo((b['balance'] as double).abs())
      );

      // Process settlements starting with smallest balance groups
      for (var groupData in groupBalances) {
        if (remainingAmount <= 0) break;

        final group = groupData['group'] as Group;
        final groupBalance = (groupData['balance'] as double).abs();

        // Skip if group has no balance
        if (groupBalance <= 0) continue;

        // Calculate how much can be settled in this group
        double groupSettlementAmount = groupBalance <= remainingAmount
            ? groupBalance  // Settle the entire group balance
            : remainingAmount;  // Settle partial amount

        if (groupSettlementAmount > 0) {
          // Create settlement record for this group
          final settlementExpense = Expense(
              totalAmount: groupSettlementAmount,
              divisionMethod: DivisionMethod.equal,
              paidByMember: payer,
              splits: [ExpenseSplit(member: receiver, amount: groupSettlementAmount)],
              description: 'Settlement in ${group.groupName}',
              group: group
          );

          expenseSettlements.add(
            ExpenseSettlement(
              expense: settlementExpense,
              settledAmount: groupSettlementAmount,
            ),
          );

          // Update remaining amount
          remainingAmount -= groupSettlementAmount;

          // Calculate new balance for the group
          final newBalance = (groupData['balance'] as double) > 0
              ? (groupData['balance'] as double) - groupSettlementAmount
              : (groupData['balance'] as double) + groupSettlementAmount;

          // Update group data
          updatedBalances.add({
            'group': group,
            'balance': newBalance,
            'isSettled': newBalance.abs() < 0.01,
            'settledAmount': groupSettlementAmount
          });
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

      // Update UI with new balances
      for (var updatedGroup in updatedBalances) {
        final index = groupBalances.indexWhere(
                (g) => (g['group'] as Group).id == (updatedGroup['group'] as Group).id
        );
        if (index != -1) {
          groupBalances[index]['balance'] = updatedGroup['balance'];
          groupBalances[index]['isSettled'] = updatedGroup['isSettled'];
        }
      }

      // Update UI across the app
      _updateUIAfterSettlement();

      Get.snackbar(
        'Success',
        'Settlement recorded successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      if (remainingAmount > 0) {
        Get.snackbar(
          'Note',
          'Remaining amount of ₹${remainingAmount.toStringAsFixed(2)} will be settled in future transactions',
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      Get.back();

    } catch (e) {
      print('Settlement error: $e');
      Get.snackbar(
        'Error',
        'Failed to record settlement: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _updateUIAfterSettlement() {
    try {
      // Update Dashboard
      final dashboardController = Get.find<DashboardController>();
      dashboardController.loadGroups();
      dashboardController.getBalanceText();

      // Update Friends page
      final friendsController = Get.find<FriendsController>();
      friendsController.loadMembers();

      // Refresh current page
      groupBalances.refresh();

    } catch (e) {
      print('Error updating UI after settlement: $e');
    }
  }
}