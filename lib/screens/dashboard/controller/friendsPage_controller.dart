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
      final currentUserPhone = userProfile.value?.phone;
      if (currentUserPhone == null) return;

      // Get all expenses from all groups
      List<Expense> allExpenses = ExpenseManagerService.getAllExpenses();

      // Create maps to store member data
      Map<String, Member> uniqueMembers = {};
      Map<String, double> memberTotalBalances = {};

      // Process all expenses
      for (var expense in allExpenses) {
        try {
          // When current user is the payer
          if (expense.paidByMember.phone == currentUserPhone) {
            // Get all splits except current user's
            for (var split in expense.splits) {
              if (split.member.phone != currentUserPhone) {
                uniqueMembers[split.member.phone] = split.member;
                memberTotalBalances[split.member.phone] =
                    (memberTotalBalances[split.member.phone] ?? 0) + split.amount;
              }
            }
          }

          // When someone else paid
          if (expense.paidByMember.phone != currentUserPhone) {
            // Add payer to unique members
            uniqueMembers[expense.paidByMember.phone] = expense.paidByMember;

            // Find current user's split
            var currentUserSplit = expense.splits.firstWhere(
                    (split) => split.member.phone == currentUserPhone,
                orElse: () => ExpenseSplit(member: expense.paidByMember, amount: 0)
            );

            // Subtract what current user owes to the payer
            memberTotalBalances[expense.paidByMember.phone] =
                (memberTotalBalances[expense.paidByMember.phone] ?? 0) - currentUserSplit.amount;
          }
        } catch (e) {
          print('Error processing expense: ${e.toString()}');
          continue;
        }
      }

      // Convert to list format for the view
      memberBalances.value = uniqueMembers.entries.map((entry) {
        return {
          'member': entry.value,
          'balance': memberTotalBalances[entry.key] ?? 0.0,
        };
      }).toList();

      // Sort by absolute balance value (highest first)
      memberBalances.sort((a, b) => b['balance'].abs().compareTo(a['balance'].abs()));

    } catch (e) {
      print('Error loading members: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void navigateToSettlement(Member member, double balance) {
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