

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../DatabaseHelper/hive_services.dart';
import '../../../modelClass/models.dart';

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

  void loadMembers() {
    try {
      isLoading.value = true;

      // Get all groups
      final groups = ExpenseManagerService.getAllGroups();

      // Create a map to store unique members and their balances
      Map<String, Member> uniqueMembers = {};
      Map<String, double> memberTotalBalances = {};

      // Process each group
      for (var group in groups) {
        for (var member in group.members) {
          // Skip if it's the current user
          if (member.phone == userProfile.value?.phone) continue;

          // Store unique member
          uniqueMembers[member.phone] = member;

          // Calculate balance for this member in this group
          double groupBalance = ExpenseManagerService.getGroupBalance(group, member);
          memberTotalBalances[member.phone] =
              (memberTotalBalances[member.phone] ?? 0) + groupBalance;
        }
      }

      // Convert to list of maps with member and balance info
      memberBalances.value = uniqueMembers.entries.map((entry) {
        return {
          'member': entry.value,
          'balance': memberTotalBalances[entry.key] ?? 0.0,
        };
      }).toList();

      // Sort by absolute balance value (highest first)
      memberBalances.sort((a, b) =>
          b['balance'].abs().compareTo(a['balance'].abs()));

    } finally {
      isLoading.value = false;
    }
  }

  void navigateToSettlement(Member member, double balance) {
    // TODO: Implement settlement navigation
    Get.toNamed('/settlement', arguments: {
      'member': member,
      'balance': balance,
    });
  }

  String getBalanceText(double balance) {
    if (balance > 0) {
      return 'owes you ₹${balance.abs().toStringAsFixed(2)}';
    } else if (balance < 0) {
      return 'you owe ₹${balance.abs().toStringAsFixed(2)}';
    }
    return 'settled up';
  }

  Color getBalanceColor(double balance) {
    if (balance > 0) return Colors.green;
    if (balance < 0) return Colors.red;
    return Colors.grey;
  }
}