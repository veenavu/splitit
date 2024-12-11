// In friendsPage_controller.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../DatabaseHelper/hive_services.dart';
import '../../../modelClass/models.dart';
import 'package:get/get.dart';

class FriendsController extends GetxController {
  RxList<Member> allMembers = <Member>[].obs;
  RxList<Map<String, dynamic>> memberBalances = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  Rxn<Profile> userProfile = Rxn<Profile>();

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
    loadMembers();
  }

  Future<void> loadUserProfile() async {
    final box = Hive.box(ExpenseManagerService.normalBox);
    final phone = box.get("mobile");
    userProfile.value = ExpenseManagerService.getProfileByPhone(phone);
  }

  Future<void> loadMembers() async {
    try {
      isLoading.value = true;
      if (userProfile.value == null) return;

      final currentUser = Member(
        name: userProfile.value!.name,
        phone: userProfile.value!.phone,
      );

      Map<String, Map<String, dynamic>> memberBalanceMap = {};
      final allGroups = ExpenseManagerService.getAllGroups();

      // Process each group
      for (var group in allGroups) {
        final expenses = ExpenseManagerService.getExpensesByGroup(group);

        // Process each expense in the group
        for (var expense in expenses) {
          // Skip if the expense doesn't involve the current user
          if (!isUserInvolvedInExpense(expense, currentUser.phone)) continue;

          // Process payer
          if (expense.paidByMember.phone == currentUser.phone) {
            // Current user paid, others owe them
            for (var split in expense.splits) {
              if (split.member.phone != currentUser.phone) {
                _updateMemberBalance(memberBalanceMap, split.member, -split.amount);
              }
            }
          } else if (expense.paidByMember.phone != currentUser.phone) {
            // Someone else paid, check if current user owes them
            final currentUserSplit = expense.splits.firstWhereOrNull(
                    (split) => split.member.phone == currentUser.phone
            );
            if (currentUserSplit != null) {
              _updateMemberBalance(memberBalanceMap, expense.paidByMember, currentUserSplit.amount);
            }
          }
        }
      }

      // Convert the map to the required format
      memberBalances.value = memberBalanceMap.entries.map((entry) {
        return {
          'member': entry.value['member'] as Member,
          'balance': entry.value['balance'] as double,
        };
      }).toList();

      // Sort by absolute balance amount
      memberBalances.sort((a, b) =>
          (b['balance'] as double).abs().compareTo((a['balance'] as double).abs())
      );

    } catch (e) {
      print('Error loading members: $e');
    } finally {
      isLoading.value = false;
    }
  }

  bool isUserInvolvedInExpense(Expense expense, String userPhone) {
    return expense.paidByMember.phone == userPhone ||
        expense.splits.any((split) => split.member.phone == userPhone);
  }

  void _updateMemberBalance(
      Map<String, Map<String, dynamic>> balanceMap,
      Member member,
      double amount
      ) {
    if (!balanceMap.containsKey(member.phone)) {
      balanceMap[member.phone] = {
        'member': member,
        'balance': 0.0,
      };
    }
    balanceMap[member.phone]!['balance'] =
        (balanceMap[member.phone]!['balance'] as double) + amount;
  }

  String getBalanceText(double balance) {
    if (balance > 0) {
      return 'you owe ₹${balance.abs().toStringAsFixed(2)}';
    } else if (balance < 0) {
      return 'owes you ₹${balance.abs().toStringAsFixed(2)}';
    }
    return 'settled up';
  }

  Color getBalanceColor(double balance) {
    if (balance > 0) return Colors.red;    // You owe them
    if (balance < 0) return Colors.green;  // They owe you
    return Colors.grey;
  }

  void refreshData() {
    loadMembers();
  }
}