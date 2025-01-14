import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../../modelClass/models.dart';
import '../../../DatabaseHelper/hive_services.dart';
class SettlementHistoryController extends GetxController {
  final RxList<Settlement> settlements = <Settlement>[].obs;
  final RxBool isLoading = true.obs;
  final Rxn<Profile> currentUser = Rxn<Profile>();

  @override
  void onInit() {
    super.onInit();
    loadCurrentUser();
    loadSettlements();
  }

  Future<void> loadCurrentUser() async {
    final box = Hive.box(ExpenseManagerService.normalBox);
    final phone = box.get("mobile");
    currentUser.value = ExpenseManagerService.getProfileByPhone(phone);
  }

  Future<void> loadSettlements() async {
    try {
      isLoading.value = true;

      final box = Hive.box<Settlement>(ExpenseManagerService.settlementBoxName);
      final currentUserPhone = currentUser.value?.phone;

      if (currentUserPhone != null) {
        final allSettlements = box.values.where((settlement) =>
        settlement.payer.phone == currentUserPhone ||
            settlement.receiver.phone == currentUserPhone
        ).toList();

        allSettlements.sort((a, b) => b.settledAt.compareTo(a.settledAt));
        settlements.assignAll(allSettlements);
      }
    } catch (e) {
      print('Error loading settlements: $e');
      Get.snackbar(
        'Error',
        'Failed to load settlement history',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> editSettlement(Settlement settlement, double newAmount) async {
    try {
      // Validate the new amount
      if (newAmount <= 0) {
        throw Exception('Settlement amount must be greater than zero');
      }

      final box = Hive.box<Settlement>(ExpenseManagerService.settlementBoxName);

      // Update the settlement amount
      settlement.amount = newAmount;
      await settlement.save();

      // Recalculate balances
      await ExpenseManagerService.recalculateAllBalances();

      // Reload settlements
      await loadSettlements();

      Get.snackbar(
        'Success',
        'Settlement updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

    } catch (e) {
      print('Error editing settlement: $e');
      Get.snackbar(
        'Error',
        'Failed to update settlement: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  Future<void> deleteSettlement(Settlement settlement) async {
    try {
      // Delete the settlement
      await settlement.delete();

      // Recalculate balances
      await ExpenseManagerService.recalculateAllBalances();

      // Reload settlements
      await loadSettlements();

      Get.snackbar(
        'Success',
        'Settlement deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

    } catch (e) {
      print('Error deleting settlement: $e');
      Get.snackbar(
        'Error',
        'Failed to delete settlement: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  String getRelativeTimeText(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  String getSettlementDescription(Settlement settlement) {
    final isCurrentUserPayer = settlement.payer.phone == currentUser.value?.phone;
    return isCurrentUserPayer
        ? 'You paid ${settlement.receiver.name}'
        : '${settlement.payer.name} paid you';
  }

  bool isUserInvolved(String phone) {
    return currentUser.value?.phone == phone;
  }
}