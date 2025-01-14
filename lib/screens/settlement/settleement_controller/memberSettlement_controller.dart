import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../DatabaseHelper/hive_services.dart';
import '../../../modelClass/models.dart';
import '../../dashboard/controller/dashboard_controller.dart';
import '../../dashboard/controller/friendsPage_controller.dart';
import '../settlement_services.dart';

class MemberSettlementController extends GetxController {
  final RxList<Map<String, dynamic>> groupBalances = <Map<String, dynamic>>[].obs;
  final RxDouble customAmount = 0.0.obs;
  final RxBool isCustomAmount = false.obs;
  final Rxn<Profile> currentUser = Rxn<Profile>();
  final RxBool isProcessing = false.obs;

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

  void initializeWithMember(Member member, double totalBalance) async {
    if (currentUser.value == null) return;

    customAmount.value = totalBalance.abs();

    groupBalances.clear();
    final allGroups = ExpenseManagerService.getAllGroups();
    final currentUserMember = Member(
      name: currentUser.value!.name,
      phone: currentUser.value!.phone,
      imagePath: currentUser.value!.imagePath,
    );

    // Calculate and add balances for each group
    for (var group in allGroups) {
      double balance = calculateGroupBalance(group, currentUserMember, member);

      // Only add groups where there is a remaining balance
      if (balance.abs() > 0.01) {
        groupBalances.add({
          'group': group,
          'balance': balance,
          'isSettled': false,
        });
      }
    }

    // Sort by absolute balance amount (highest first)
    groupBalances.sort((a, b) =>
        (b['balance'] as double).abs().compareTo((a['balance'] as double).abs())
    );
  }

  double calculateGroupBalance(Group group, Member currentUser, Member otherMember) {
    double balance = 0.0;
    final expenses = ExpenseManagerService.getExpensesByGroup(group);

    for (var expense in expenses) {
      if (expense.status == ExpenseStatus.fullySettled) continue;

      // Get the original splits
      final userSplit = expense.getSplitForMember(currentUser);
      final otherSplit = expense.getSplitForMember(otherMember);

      if (userSplit == null || otherSplit == null) continue;

      // Calculate settled amounts from settlements
      double userSettledAmount = 0.0;
      double otherSettledAmount = 0.0;

      if (expense.settlements != null) {
        for (var settlement in expense.settlements) {
          if (settlement.payer.phone == currentUser.phone) {
            userSettledAmount += settlement.amount;
          } else if (settlement.payer.phone == otherMember.phone) {
            otherSettledAmount += settlement.amount;
          }
        }
      }

      // Calculate remaining amounts after settlements
      if (expense.paidByMember.phone == currentUser.phone) {
        // Current user paid, they should receive money
        balance += otherSplit.amount - otherSettledAmount;
      } else if (expense.paidByMember.phone == otherMember.phone) {
        // Other member paid, current user should pay
        balance -= (userSplit.amount - userSettledAmount);
      }
    }

    return balance;
  }


  bool isUserOwing(double balance) {
    return balance < 0;
  }

  Future<void> recordSettlement({
    required Member payer,
    required Member receiver,
    required double amount,
    required List<Group> selectedGroups,
  }) async {
    try {
      isProcessing.value = true;

      await SettlementHandler.processSettlement(
        payer: payer,
        receiver: receiver,
        amount: amount,
        selectedGroups: selectedGroups,
      );

      // Update UI
      if (Get.isRegistered<FriendsController>()) {
        await Get.find<FriendsController>().handleSuccessfulSettlement();
      }

      // Update dashboard
      Get.find<DashboardController>().loadGroups();
      Get.find<DashboardController>().getBalanceText();

      Get.back();
      Get.snackbar(
        'Success',
        'Settlement recorded successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

    } catch (e) {
      print('Settlement error: $e');
      Get.snackbar(
        'Error',
        'Failed to record settlement: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  String getBalanceText(double balance, {Member? member}) {
    if (balance > 0) {
      return '${member?.name ?? ""} Owes you ₹${balance.abs().toStringAsFixed(2)}';
    } else if (balance < 0) {
      return 'You owe ${member?.name ?? ""} ₹${balance.abs().toStringAsFixed(2)}';
    }
    return 'Settled up';
  }

}