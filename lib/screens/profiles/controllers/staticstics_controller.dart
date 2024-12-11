import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../../DatabaseHelper/hive_services.dart';
import '../../../modelClass/models.dart';

class StatisticsController extends GetxController {
  final RxList<Map<String, dynamic>> groupsOwedStats = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> groupsOwesStats = <Map<String, dynamic>>[].obs;
  final RxDouble totalSpent = 0.0.obs;
  final RxMap<String, double> categorySpending = <String, double>{}.obs;
  final Rxn<Profile> currentUser = Rxn<Profile>();
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadStatistics();
  }

  Future<void> loadStatistics() async {
    try {
      isLoading.value = true;

      // Load current user
      final box = Hive.box(ExpenseManagerService.normalBox);
      final phone = box.get("mobile");
      currentUser.value = ExpenseManagerService.getProfileByPhone(phone);

      if (currentUser.value == null) return;

      // Create member object for current user
      final currentMember = Member(
        name: currentUser.value!.name,
        phone: currentUser.value!.phone,
        imagePath: currentUser.value!.imagePath,
      );

      // Get groups that owe you
      final groupsOwed = ExpenseManagerService.getGroupsThatOweYou(currentMember);
      groupsOwedStats.value = groupsOwed.map((group) {
        final balance = ExpenseManagerService.getGroupBalance(group, currentMember);
        return {
          'group': group,
          'amount': balance.abs(),
        };
      }).toList();

      // Get groups you owe
      final groupsOwes = ExpenseManagerService.getGroupsYouOwe(currentMember);
      groupsOwesStats.value = groupsOwes.map((group) {
        final balance = ExpenseManagerService.getGroupBalance(group, currentMember);
        return {
          'group': group,
          'amount': balance.abs(),
        };
      }).toList();

      // Calculate total spending and category statistics
      final netWorth = ExpenseManagerService.getMemberNetWorth(currentMember);
      categorySpending.value = netWorth.categoryTotals;

      // Calculate total spent
      totalSpent.value = netWorth.categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

    } catch (e) {
      print('Error loading statistics: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to get color based on amount
  Color getAmountColor(double amount) {
    return amount > 0 ? Colors.green : Colors.red;
  }

  // Helper method to format currency
  String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }
}