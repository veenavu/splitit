import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../modelClass/models.dart';
import '../../../DatabaseHelper/hive_services.dart';
import '../../dashboard/controller/dashboard_controller.dart';
import '../../dashboard/controller/friendsPage_controller.dart';
import '../settlement_services.dart';
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
        final memberSplit = _findSplit(expense.splits, member.phone);
        if (memberSplit != null) {
          balance += memberSplit.amount;
        }
      } else if (expense.paidByMember.phone == member.phone) {
        // Member paid, check if current user owes
        final currentUserSplit = _findSplit(expense.splits, currentUser.value!.phone);
        if (currentUserSplit != null) {
          balance -= currentUserSplit.amount;
        }
      }
    }

    return balance;
  }

  /// Helper method to find split for a member
  ExpenseSplit? _findSplit(List<ExpenseSplit> splits, String phone) {
    try {
      return splits.firstWhere((split) => split.member.phone == phone);
    } catch (e) {
      return null;
    }
  }

  Future<void> recordSettlement({
    required Member payer,
    required Member receiver,
    required double amount,
    required List<Group> selectedGroups,
  }) async {
    try {
      // Get involved groups (groups with non-zero balances)
      final involvedGroups = groupBalances
          .where((g) => (g['balance'] as double).abs() > 0.01)
          .map((g) => g['group'] as Group)
          .toList();

      // Record the settlement using the SettlementService
      final settlement = await SettlementService.recordSettlement(
        payer: payer,
        receiver: receiver,
        amount: amount,
        groups: involvedGroups,
      );

      // Update UI to reflect the settlement
      await _updateGroupBalancesAfterSettlement(
        settlement: settlement,
        payer: payer,
        receiver: receiver,
      );

      // Update UI across the app
      _updateUIAfterSettlement();

      Get.snackbar(
        'Success',
        'Settlement recorded successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

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

  Future<void> _updateGroupBalancesAfterSettlement({
    required Settlement settlement,
    required Member payer,
    required Member receiver,
  }) async {
    // Group settlements by group
    Map<int?, double> settledAmountsByGroup = {};

    for (var expenseSettlement in settlement.expenseSettlements) {
      final groupId = expenseSettlement.expense.group?.id;
      if (groupId != null) {
        settledAmountsByGroup[groupId] = (settledAmountsByGroup[groupId] ?? 0) +
            expenseSettlement.settledAmount;
      }
    }

    // Update group balances in the UI
    for (var groupData in groupBalances) {
      final group = groupData['group'] as Group;
      final settledAmount = settledAmountsByGroup[group.id] ?? 0;

      if (settledAmount > 0) {
        final newBalance = (groupData['balance'] as double) > 0
            ? (groupData['balance'] as double) - settledAmount
            : (groupData['balance'] as double) + settledAmount;

        groupData['balance'] = newBalance;
        groupData['isSettled'] = newBalance.abs() < 0.01;
      }
    }

    groupBalances.refresh();
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

    } catch (e) {
      print('Error updating UI after settlement: $e');
    }
  }
}