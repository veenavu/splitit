// In friendsPage_controller.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';

import '../../../DatabaseHelper/hive_services.dart';
import '../../../modelClass/models.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:get/get.dart';
import '../../../DatabaseHelper/hive_services.dart';
import '../../../modelClass/models.dart';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:get/get.dart';
import '../../../DatabaseHelper/hive_services.dart';
import '../../../modelClass/models.dart';
//
// class FriendsController extends GetxController {
//   RxList<Map<String, dynamic>> memberBalances = <Map<String, dynamic>>[].obs;
//   final RxBool isLoading = true.obs;
//   Rxn<Profile> userProfile = Rxn<Profile>();
//
//   @override
//   void onInit() {
//     super.onInit();
//     loadUserProfile();
//     loadMembers();
//   }
//
//   Future<void> loadUserProfile() async {
//     try {
//       final box = Hive.box(ExpenseManagerService.normalBox);
//       final phone = box.get("mobile");
//       if (phone != null) {
//         userProfile.value = ExpenseManagerService.getProfileByPhone(phone);
//       }
//     } catch (e) {
//       print('Error loading user profile: $e');
//     }
//   }
//
//   Future<void> loadMembers() async {
//     try {
//       isLoading.value = true;
//       if (userProfile.value == null) return;
//
//       final currentUser = Member(
//         name: userProfile.value!.name,
//         phone: userProfile.value!.phone,
//         imagePath: userProfile.value!.imagePath,
//       );
//
//       Map<String, Map<String, dynamic>> memberBalanceMap = {};
//       final allGroups = ExpenseManagerService.getAllGroups();
//
//       // Initialize member balances
//       for (var group in allGroups) {
//         for (var member in group.members) {
//           if (member.phone != currentUser.phone) {
//             memberBalanceMap[member.phone] ??= {
//               'member': member,
//               'totalBalance': 0.0,
//               'groupBalances': <String, double>{},
//               'hasTransactions': false,
//               'unsettledExpenses': <Expense>[],
//             };
//           }
//         }
//       }
//
//       // Process each group's expenses and settlements
//       for (var group in allGroups) {
//         final expenses = ExpenseManagerService.getExpensesByGroup(group);
//         final groupId = group.id?.toString() ?? 'unknown';
//
//         for (var expense in expenses) {
//           if (expense.status == ExpenseStatus.fullySettled) continue;
//
//           // Calculate remaining amounts after settlements
//           double calculatedAmount = _calculateExpenseAmount(
//               expense: expense,
//               currentUser: currentUser,
//               memberBalanceMap: memberBalanceMap,
//               groupId: groupId
//           );
//
//           // Update member balance if there's an unsettled amount
//           if (calculatedAmount != 0) {
//             final memberPhone = expense.paidByMember.phone == currentUser.phone ?
//             _getOtherMemberPhone(expense, currentUser.phone) :
//             expense.paidByMember.phone;
//
//             final memberData = memberBalanceMap[memberPhone];
//             if (memberData != null) {
//               memberData['totalBalance'] = (memberData['totalBalance'] as double) + calculatedAmount;
//               (memberData['groupBalances'] as Map<String, double>)[groupId] =
//                   ((memberData['groupBalances'] as Map<String, double>)[groupId] ?? 0.0) + calculatedAmount;
//               memberData['hasTransactions'] = true;
//               (memberData['unsettledExpenses'] as List<Expense>).add(expense);
//             }
//           }
//         }
//       }
//
//       // Process settlements
//       final settlements = Hive.box<Settlement>(ExpenseManagerService.settlementBoxName).values;
//       for (var settlement in settlements) {
//         _processSettlement(
//             settlement: settlement,
//             currentUser: currentUser,
//             memberBalanceMap: memberBalanceMap
//         );
//       }
//
//       // Filter and sort results
//       memberBalances.value = memberBalanceMap.values
//           .where((data) =>
//       (data['hasTransactions'] as bool) &&
//           ((data['totalBalance'] as double).abs() > 0.01))
//           .map((data) => {
//         'member': data['member'] as Member,
//         'balance': data['totalBalance'] as double,
//         'groupBalances': data['groupBalances'] as Map<String, double>,
//         'unsettledExpenses': data['unsettledExpenses'] as List<Expense>
//       })
//           .toList()
//         ..sort((a, b) => (b['balance'] as double).abs()
//             .compareTo((a['balance'] as double).abs()));
//
//     } catch (e) {
//       print('Error loading members: $e');
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   double _calculateExpenseAmount({
//     required Expense expense,
//     required Member currentUser,
//     required Map<String, Map<String, dynamic>> memberBalanceMap,
//     required String groupId
//   }) {
//     double amount = 0.0;
//
//     if (expense.paidByMember.phone == currentUser.phone) {
//       // Current user paid - calculate amount others owe
//       for (var split in expense.splits) {
//         if (split.member.phone != currentUser.phone) {
//           // Calculate remaining amount after settlements
//           double settledAmount = expense.settlements
//               .where((s) => s.payer.phone == split.member.phone)
//               .fold(0.0, (sum, s) => sum + s.amount);
//
//           amount += split.amount - settledAmount;
//         }
//       }
//     } else {
//       // Someone else paid - calculate what current user owes
//       final userSplit = expense.splits.firstWhere(
//               (split) => split.member.phone == currentUser.phone,
//           orElse: () => ExpenseSplit(member: currentUser, amount: 0)
//       );
//
//       // Calculate remaining amount after settlements
//       double settledAmount = expense.settlements
//           .where((s) => s.payer.phone == currentUser.phone)
//           .fold(0.0, (sum, s) => sum + s.amount);
//
//       amount = -(userSplit.amount - settledAmount);
//     }
//
//     return amount;
//   }
//
//   void _processSettlement({
//     required Settlement settlement,
//     required Member currentUser,
//     required Map<String, Map<String, dynamic>> memberBalanceMap
//   }) {
//     String relevantMemberPhone;
//     double balanceAdjustment;
//
//     if (settlement.payer.phone == currentUser.phone) {
//       relevantMemberPhone = settlement.receiver.phone;
//       balanceAdjustment = settlement.amount;
//     } else if (settlement.receiver.phone == currentUser.phone) {
//       relevantMemberPhone = settlement.payer.phone;
//       balanceAdjustment = -settlement.amount;
//     } else {
//       return; // Settlement doesn't involve current user
//     }
//
//     final memberData = memberBalanceMap[relevantMemberPhone];
//     if (memberData != null) {
//       memberData['totalBalance'] = (memberData['totalBalance'] as double) + balanceAdjustment;
//
//       // Update group balances for affected groups
//       for (var expenseSettlement in settlement.expenseSettlements) {
//         if (expenseSettlement.expense.group != null) {
//           final groupId = expenseSettlement.expense.group!.id.toString();
//           (memberData['groupBalances'] as Map<String, double>)[groupId] =
//               ((memberData['groupBalances'] as Map<String, double>)[groupId] ?? 0.0) +
//                   (balanceAdjustment / settlement.expenseSettlements.length); // Distribute evenly across groups
//         }
//       }
//     }
//   }
//
//   String _getOtherMemberPhone(Expense expense, String currentUserPhone) {
//     return expense.splits
//         .firstWhere((split) => split.member.phone != currentUserPhone)
//         .member.phone;
//   }
//
//   String getBalanceText(double balance) {
//     if (balance.abs() < 0.01) return 'settled up';
//     if (balance > 0) {
//       return 'you owe ₹${balance.toStringAsFixed(2)}';
//     } else {
//       return 'owes you ₹${(-balance).toStringAsFixed(2)}';
//     }
//   }
//
//   Color getBalanceColor(double balance) {
//     if (balance.abs() < 0.01) return Colors.grey;
//     return balance > 0 ? Colors.red : Colors.green;
//   }
//
//   Future<void> handleSuccessfulSettlement() async {
//     await loadMembers();
//     update();
//   }
// }



//
//
// class FriendsController extends GetxController {
//   RxList<Map<String, dynamic>> memberBalances = <Map<String, dynamic>>[].obs;
//   final RxBool isLoading = true.obs;
//   Rxn<Profile> userProfile = Rxn<Profile>();
//
//   @override
//   void onInit() {
//     super.onInit();
//     loadUserProfile();
//     loadMembers();
//   }
//
//   Future<void> loadUserProfile() async {
//     try {
//       final box = Hive.box(ExpenseManagerService.normalBox);
//       final phone = box.get("mobile");
//       if (phone != null) {
//         userProfile.value = ExpenseManagerService.getProfileByPhone(phone);
//       }
//     } catch (e) {
//       print('Error loading user profile: $e');
//     }
//   }
//
//   Future<void> loadMembers() async {
//     try {
//       isLoading.value = true;
//       if (userProfile.value == null) {
//         print('User profile is null');
//         return;
//       }
//
//       final currentUser = Member(
//         name: userProfile.value!.name,
//         phone: userProfile.value!.phone,
//         imagePath: userProfile.value!.imagePath,
//       );
//
//       Map<String, Map<String, dynamic>> memberBalanceMap = {};
//       final allGroups = ExpenseManagerService.getAllGroups();
//
//       // Initialize member balances
//       for (var group in allGroups) {
//         for (var member in group.members) {
//           if (member.phone != currentUser.phone) {
//             memberBalanceMap[member.phone] ??= {
//               'member': member,
//               'totalBalance': 0.0,
//               'hasTransactions': false,
//               'groupBalances': <String, double>{},
//               'settlements': <Settlement>[],  // Track settlements
//             };
//           }
//         }
//       }
//
//       // Process all expenses
//       for (var group in allGroups) {
//         final expenses = ExpenseManagerService.getExpensesByGroup(group);
//         final groupId = group.id?.toString() ?? 'unknown';
//
//         for (var expense in expenses) {
//           if (expense.status == ExpenseStatus.fullySettled) continue;
//
//           if (expense.paidByMember.phone == currentUser.phone) {
//             // Current user paid
//             for (var split in expense.splits) {
//               if (split.member.phone != currentUser.phone) {
//                 final memberData = memberBalanceMap[split.member.phone];
//                 if (memberData != null) {
//                   memberData['totalBalance'] = (memberData['totalBalance'] as double) - split.amount;
//                   (memberData['groupBalances'] as Map<String, double>)[groupId] =
//                       ((memberData['groupBalances'] as Map<String, double>)[groupId] ?? 0.0) - split.amount;
//                   memberData['hasTransactions'] = true;
//                 }
//               }
//             }
//           } else {
//             // Someone else paid
//             if (memberBalanceMap.containsKey(expense.paidByMember.phone)) {
//               final currentUserSplit = expense.splits.firstWhere(
//                       (split) => split.member.phone == currentUser.phone,
//                   orElse: () => ExpenseSplit(member: currentUser, amount: 0)
//               );
//
//               final memberData = memberBalanceMap[expense.paidByMember.phone];
//               if (memberData != null && !expense.settlements.any((s) =>
//               s.payer.phone == currentUser.phone &&
//                   s.receiver.phone == expense.paidByMember.phone)) {
//                 memberData['totalBalance'] = (memberData['totalBalance'] as double) + currentUserSplit.amount;
//                 (memberData['groupBalances'] as Map<String, double>)[groupId] =
//                     ((memberData['groupBalances'] as Map<String, double>)[groupId] ?? 0.0) + currentUserSplit.amount;
//                 memberData['hasTransactions'] = true;
//               }
//             }
//           }
//         }
//       }
//
//       // Process settlements
//       final settlements = Hive.box<Settlement>(ExpenseManagerService.settlementBoxName).values;
//       for (var settlement in settlements) {
//         if (settlement.payer.phone == currentUser.phone) {
//           final memberData = memberBalanceMap[settlement.receiver.phone];
//           if (memberData != null) {
//             memberData['totalBalance'] = (memberData['totalBalance'] as double) - settlement.amount;
//             (memberData['settlements'] as List<Settlement>).add(settlement);
//           }
//         } else if (settlement.receiver.phone == currentUser.phone) {
//           final memberData = memberBalanceMap[settlement.payer.phone];
//           if (memberData != null) {
//             memberData['totalBalance'] = (memberData['totalBalance'] as double) + settlement.amount;
//             (memberData['settlements'] as List<Settlement>).add(settlement);
//           }
//         }
//       }
//
//       // Filter and sort results
//       memberBalances.value = memberBalanceMap.values
//           .where((data) =>
//       (data['hasTransactions'] as bool) &&
//           ((data['totalBalance'] as double).abs() > 0.01))
//           .map((data) => {
//         'member': data['member'] as Member,
//         'totalBalance': data['totalBalance'] as double,
//         'groupBalances': data['groupBalances'] as Map<String, double>,
//       })
//           .toList()
//         ..sort((a, b) => (b['totalBalance'] as double).abs()
//             .compareTo((a['totalBalance'] as double).abs()));
//
//     } catch (e) {
//       print('Error loading members: $e');
//     } finally {
//       isLoading.value = false;
//     }
//   }
//   String getBalanceText(double balance) {
//     if (balance.abs() < 0.01) return 'settled up';
//     if (balance > 0) {
//       return 'you owe ₹${balance.toStringAsFixed(2)}';
//     } else {
//       return 'owes you ₹${(-balance).toStringAsFixed(2)}';
//     }
//   }
//
//   Color getBalanceColor(double balance) {
//     if (balance.abs() < 0.01) return Colors.grey;
//     return balance > 0 ? Colors.red : Colors.green;
//   }
//
//   Future<void> handleSuccessfulSettlement() async {
//     await loadMembers();
//     update();
//   }
// }
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import '../../../DatabaseHelper/hive_services.dart';
import '../../../modelClass/models.dart';

class FriendsController extends GetxController {
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
    try {
      final box = Hive.box(ExpenseManagerService.normalBox);
      final phone = box.get("mobile");
      if (phone != null) {
        userProfile.value = ExpenseManagerService.getProfileByPhone(phone);
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }
  Future<void> loadMembers() async {
    try {
      isLoading.value = true;
      if (userProfile.value == null) return;

      final currentUser = Member(
        name: userProfile.value!.name,
        phone: userProfile.value!.phone,
        imagePath: userProfile.value!.imagePath,
      );

      Map<String, Map<String, dynamic>> memberBalanceMap = {};
      final allGroups = ExpenseManagerService.getAllGroups();

      // Initialize member balances
      for (var group in allGroups) {
        for (var member in group.members) {
          if (member.phone != currentUser.phone) {
            memberBalanceMap[member.phone] ??= {
              'member': member,
              'balance': 0.0,
              'groupBalances': <String, double>{},
              'hasTransactions': false
            };
          }
        }
      }

      // Process expenses and calculate balances
      for (var group in allGroups) {
        final expenses = ExpenseManagerService.getExpensesByGroup(group);

        for (var expense in expenses) {
          if (expense.status == ExpenseStatus.fullySettled) continue;

          if (expense.paidByMember.phone == currentUser.phone) {
            // Current user paid, others owe money
            for (var split in expense.splits) {
              if (split.member.phone != currentUser.phone) {
                final memberData = memberBalanceMap[split.member.phone];
                if (memberData != null) {
                  memberData['balance'] = (memberData['balance'] as double) - split.amount;
                  memberData['groupBalances'][group.id.toString()] =
                      (memberData['groupBalances'][group.id.toString()] ?? 0.0) - split.amount;
                  memberData['hasTransactions'] = true;
                }
              }
            }
          } else {
            // Someone else paid, check if current user owes
            if (memberBalanceMap.containsKey(expense.paidByMember.phone)) {
              final currentUserSplit = expense.splits.firstWhere(
                    (split) => split.member.phone == currentUser.phone,
                orElse: () => ExpenseSplit(member: currentUser, amount: 0),
              );

              if (currentUserSplit.amount > 0) {
                final memberData = memberBalanceMap[expense.paidByMember.phone];
                if (memberData != null) {
                  memberData['balance'] = (memberData['balance'] as double) + currentUserSplit.amount;
                  memberData['groupBalances'][group.id.toString()] =
                      (memberData['groupBalances'][group.id.toString()] ?? 0.0) + currentUserSplit.amount;
                  memberData['hasTransactions'] = true;
                }
              }
            }
          }
        }
      }

      // Process settlements
      final settlements = Hive.box<Settlement>(ExpenseManagerService.settlementBoxName).values;
      for (var settlement in settlements) {
        if (settlement.payer.phone == currentUser.phone) {
          final memberData = memberBalanceMap[settlement.receiver.phone];
          if (memberData != null) {
            memberData['balance'] = (memberData['balance'] as double) - settlement.amount;
            // Update group balances proportionally
            _distributeSettlementAmount(settlement, memberData['groupBalances'] as Map<String, double>, -settlement.amount);
          }
        } else if (settlement.receiver.phone == currentUser.phone) {
          final memberData = memberBalanceMap[settlement.payer.phone];
          if (memberData != null) {
            memberData['balance'] = (memberData['balance'] as double) + settlement.amount;
            // Update group balances proportionally
            _distributeSettlementAmount(settlement, memberData['groupBalances'] as Map<String, double>, settlement.amount);
          }
        }
      }

      // Filter and sort results - only include members with non-zero balances
      memberBalances.value = memberBalanceMap.values
          .where((data) =>
      (data['hasTransactions'] as bool) &&
          ((data['balance'] as double).abs() > 0.01))
          .map((data) => {
        'member': data['member'] as Member,
        'balance': data['balance'] as double,
        'groupBalances': data['groupBalances'] as Map<String, double>,
      })
          .toList()
        ..sort((a, b) => (b['balance'] as double).abs()
            .compareTo((a['balance'] as double).abs()));

    } catch (e) {
      print('Error loading members: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _distributeSettlementAmount(
      Settlement settlement,
      Map<String, double> groupBalances,
      double amount
      ) {
    final affectedGroups = settlement.expenseSettlements
        .map((es) => es.expense.group?.id.toString())
        .where((id) => id != null)
        .toSet();

    if (affectedGroups.isEmpty) return;

    final amountPerGroup = amount / affectedGroups.length;
    for (var groupId in affectedGroups) {
      if (groupId != null) {
        groupBalances[groupId] = (groupBalances[groupId] ?? 0.0) + amountPerGroup;
      }
    }
  }

  String getBalanceText(double balance) {
    if (balance.abs() < 0.01) return 'settled up';
    if (balance > 0) {
      return 'you owe ₹${balance.toStringAsFixed(2)}';
    } else {
      return 'owes you ₹${(-balance).toStringAsFixed(2)}';
    }
  }

  Color getBalanceColor(double balance) {
    if (balance.abs() < 0.01) return Colors.grey;
    return balance > 0 ? Colors.red : Colors.green;
  }

  Future<void> handleSuccessfulSettlement() async {
    await loadMembers();
    update();
  }
}