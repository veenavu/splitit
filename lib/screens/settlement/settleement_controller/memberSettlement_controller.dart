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
  final RxBool isProcessing = false.obs;
  final RxDouble totalBalance = 0.0.obs;

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

  // Initialize with member data when page loads
  Future<void> initializeWithMember(Member member, double balance) async {
    if (currentUser.value == null) return;

    totalBalance.value = balance;
    // Set initial custom amount
    customAmount.value = balance.abs();

    // Clear and load group balances
    groupBalances.clear();
    final allGroups = ExpenseManagerService.getAllGroups();
    final currentUserMember = Member(
      name: currentUser.value!.name,
      phone: currentUser.value!.phone,
      imagePath: currentUser.value!.imagePath,
    );

    for (var group in allGroups) {
      // Calculate balance between current user and member for this group
      double balance = 0.0;
      final expenses = ExpenseManagerService.getExpensesByGroup(group);

      for (var expense in expenses) {
        if (expense.paidByMember.phone == currentUserMember.phone) {
          // Current user paid
          final memberSplit = expense.splits.firstWhereOrNull(
                  (split) => split.member.phone == member.phone
          );
          if (memberSplit != null) {
            balance -= memberSplit.amount;
          }
        } else if (expense.paidByMember.phone == member.phone) {
          // Member paid
          final currentUserSplit = expense.splits.firstWhereOrNull(
                  (split) => split.member.phone == currentUserMember.phone
          );
          if (currentUserSplit != null) {
            balance += currentUserSplit.amount;
          }
        }
      }

      // Only include groups with unsettled balances
      if (balance.abs() > 0.01) {
        groupBalances.add({
          'group': group,
          'balance': balance,
          'isSettled': false,
        });
      }
    }

    // Sort by absolute balance amount
    groupBalances.sort((a, b) =>
        (b['balance'] as double).abs().compareTo((a['balance'] as double).abs())
    );
  }

  // Add the missing isUserOwing method
  bool isUserOwing(double balance) {
    return balance > 0;  // If balance is positive, current user owes money
  }

  Future<void> recordSettlement({
    required Member payer,
    required Member receiver,
    required double amount,
    required List<Group> selectedGroups,
  }) async {
    try {
      isProcessing.value = true;

      // Calculate total owed amount before settlement
      double totalOwedAmount = totalBalance.value.abs();

      // Ensure amount doesn't exceed total owed
      final settleAmount = amount.clamp(0.0, totalOwedAmount);

      // Record partial settlement
      await SettlementService.recordPartialSettlement(
        payer: payer,
        receiver: receiver,
        amount: settleAmount,
        totalOwedAmount: totalOwedAmount,
        groups: selectedGroups,
      );

      // Update UI
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().loadGroups();
      }
      if (Get.isRegistered<FriendsController>()) {
        Get.find<FriendsController>().loadMembers();
      }

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
    } finally {
      isProcessing.value = false;
    }
  }

  String getBalanceText(double balance) {
    if (balance > 0) {
      return 'You owe ₹${balance.abs().toStringAsFixed(2)}';
    } else if (balance < 0) {
      return 'Owes you ₹${balance.abs().toStringAsFixed(2)}';
    }
    return 'Settled up';
  }
}