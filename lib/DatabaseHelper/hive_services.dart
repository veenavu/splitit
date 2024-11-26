import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../modelClass/models.dart';

class ExpenseManagerService {
  static const String profileBoxName = 'profiles';
  static const String groupBoxName = 'groups';
  static const String memberBoxName = 'members';
  static const String expenseBoxName = 'expenses';
  static const String normalBox = 'normalBox';
  static const String counterBoxName = 'counters';

  //Add a Map to track open Boxes
  static final Map<String, Box> _openBoxes = {};

  // Initialize Hive and Register Adapters

  static Future<void> initHive() async {
try{
  await Hive.initFlutter();
  // Register Adapters
  Hive.registerAdapter(ProfileAdapter());
  Hive.registerAdapter(GroupAdapter());
  Hive.registerAdapter(MemberAdapter());
  Hive.registerAdapter(DivisionMethodAdapter());
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(ExpenseSplitAdapter());
  // Open Boxes
  await Hive.openBox<Profile>(profileBoxName);
  await Hive.openBox<Group>(groupBoxName);
  await Hive.openBox<Member>(memberBoxName);
  await Hive.openBox<Expense>(expenseBoxName);
  await Hive.openBox<int>(counterBoxName);
  await Hive.openBox(normalBox);
}catch(e){
  print(e);
}
  }

  static int _getNextId(String type) {
    final box = Hive.box<int>(counterBoxName);

    int currentId = box.get(type, defaultValue: 0)!;
    box.put(type, currentId + 1);
    return currentId + 1;
  }

  // PROFILE OPERATIONS
  static Future<void> saveProfile(Profile profile) async {
    final box = Hive.box<Profile>(profileBoxName);
    int nextId = _getNextId('profile');
    profile.id = nextId;
    await box.add(profile);
  }

  static Profile? getProfileByPhone(String phone) {
    final box = Hive.box<Profile>(profileBoxName);

    // Search through all profiles in the box
    for (int i = 0; i < box.length; i++) {
      final profile = box.getAt(i);
      if (profile?.phone == phone) {
        return profile;
      }
    }
    return null; // Return null if no profile found with given phone number
  }

  static Future<void> updateProfile(Profile profile) async {
    await profile.save();
  }

  // Modified clearAllData method

  static Group? getGroupById(int groupId) {
    final box = Hive.box<Group>(groupBoxName);
    for (var group in box.values) {
      if (group.id == groupId) {
        return group;
      }
    }
    return null;
  }

  static Future<void> saveTheGroup(Group group) async {
    try {
      final box = Hive.box<Group>(groupBoxName);
      int nextId = _getNextId("group");
      group.id = nextId;
      await box.add(group);
    } catch (e) {
      throw Exception('Failed to save group: ${e.toString()}');
    }
  }

  static List<Group> getAllGroups() {
    final box = Hive.box<Group>(groupBoxName);
    return box.values.toList();
  }

  static Group? getGroupByName(String groupName) {
    final box = Hive.box<Group>(groupBoxName);
    for (var group in box.values) {
      if (group.groupName == groupName) {
        return group;
      }
    }
    return null;
  }

  static Future<void> updateGroup(Group group) async {
    await group.save();
  }

  static Future<void> deleteGroup(Group group) async {
    // First delete all expenses in the group
    final expenses = getExpensesByGroup(group);

    for (var expense in expenses) {
      await deleteExpense(expense);
    }

    // Then delete the group itself
    await group.delete();
  }

  static List<Group> getGroupsYouOwe(Member member) {
    final allGroups = getAllGroups();
    return allGroups.where((group) {
      // Get all expenses for this group
      final groupExpenses = getExpensesByGroup(group);
      double totalLent = 0.0;
      double totalOwed = 0.0;

      for (var expense in groupExpenses) {
        // When member is the payer
        if (expense.paidByMember.phone == member.phone) {
          // Calculate amount lent to others (excluding self)
          final lentAmount = expense.splits
              .where((split) => split.member.phone != member.phone)
              .fold(0.0, (sum, split) => sum + split.amount);
          totalLent += lentAmount;
        }

        // When member owes money
        final memberSplit = expense.splits.firstWhereOrNull((split) => split.member.phone == member.phone);

        if (memberSplit != null && expense.paidByMember.phone != member.phone) {
          totalOwed += memberSplit.amount;
        }
      }

      // Return true if you owe money in this group (net negative balance)
      final netAmount = (totalLent - totalOwed).roundToDouble();
      return netAmount < 0;
    }).toList();
  }

  static List<Group> getGroupsThatOweYou(Member member) {
    final allGroups = getAllGroups();
    return allGroups.where((group) {
      // Get all expenses for this group
      final groupExpenses = getExpensesByGroup(group);
      double totalLent = 0.0;
      double totalOwed = 0.0;

      for (var expense in groupExpenses) {
        // When member is the payer
        if (expense.paidByMember.phone == member.phone) {
          // Calculate amount lent to others (excluding self)
          final lentAmount = expense.splits
              .where((split) => split.member.phone != member.phone)
              .fold(0.0, (sum, split) => sum + split.amount);
          totalLent += lentAmount;
        }

        // When member owes money
        final memberSplit = expense.splits.firstWhereOrNull((split) => split.member.phone == member.phone);

        if (memberSplit != null && expense.paidByMember.phone != member.phone) {
          totalOwed += memberSplit.amount;
        }
      }

      // Return true if others owe you money in this group (net positive balance)
      final netAmount = (totalLent - totalOwed).roundToDouble();
      return netAmount > 0;
    }).toList();
  }

// Helper function to get amount owed/to be received for a group
  static double getGroupBalance(Group group, Member member) {
    final groupExpenses = getExpensesByGroup(group);
    double totalLent = 0.0;
    double totalOwed = 0.0;

    for (var expense in groupExpenses) {
      // When member is the payer
      if (expense.paidByMember.phone == member.phone) {
        // Calculate amount lent to others (excluding self)
        final lentAmount = expense.splits
            .where((split) => split.member.phone != member.phone)
            .fold(0.0, (sum, split) => sum + split.amount);
        totalLent += lentAmount;
      }

      // When member owes money
      final memberSplit = expense.splits.firstWhereOrNull((split) => split.member.phone == member.phone);

      if (memberSplit != null && expense.paidByMember.phone != member.phone) {
        totalOwed += memberSplit.amount;
      }
    }

    return (totalLent - totalOwed).roundToDouble();
  }

  // EXPENSE OPERATIONS
  static Future<void> createExpense({
    required double totalAmount,
    required DivisionMethod divisionMethod,
    required Member paidByMember,
    required List<Member> involvedMembers,
    required String description,
    Group? group,
    List<double>? customAmounts,
    List<double>? percentages,
  }) async {
    List<ExpenseSplit> splits;

    switch (divisionMethod) {
      case DivisionMethod.equal:
        splits = _splitEqually(totalAmount, involvedMembers);
        break;

      case DivisionMethod.unequal:
        if (customAmounts == null || customAmounts.length != involvedMembers.length) {
          throw Exception('Custom amounts must be provided for unequal split');
        }
        if (customAmounts.fold<double>(0, (sum, amount) => sum + amount) != totalAmount) {
          throw Exception('Sum of custom amounts must equal total amount');
        }
        splits = Expense.createSplitsFromAmounts(involvedMembers, customAmounts);
        break;

      case DivisionMethod.percentage:
        if (percentages == null || percentages.length != involvedMembers.length) {
          throw Exception('Percentages must be provided for percentage split');
        }
        if (percentages.fold<double>(0, (sum, pct) => sum + pct) != 100) {
          throw Exception('Percentages must sum to 100');
        }
        splits = _splitByPercentage(totalAmount, involvedMembers, percentages);
        break;
    }

    final expense = Expense(
      totalAmount: totalAmount,
      divisionMethod: divisionMethod,
      paidByMember: paidByMember,
      splits: splits,
      group: group,
      description: description,
    );

    if (expense.validateSplits()) {
      final box = Hive.box<Expense>(expenseBoxName);
      await box.add(expense);
      await _updateMemberBalances(expense);
    } else {
      throw Exception('Invalid splits: Total of splits does not match expense amount');
    }
  }

  static Future<void> updateExpense({
    required Expense expense,
    required double totalAmount,
    required DivisionMethod divisionMethod,
    required Member paidByMember,
    required List<Member> involvedMembers,
    required String description,
    Group? group,
    List<double>? customAmounts,
    List<double>? percentages,
  }) async {
    // Reverse previous balance updates
    await _reverseMemberBalances(expense);

    List<ExpenseSplit> splits;
    switch (divisionMethod) {
      case DivisionMethod.equal:
        splits = _splitEqually(totalAmount, involvedMembers);
        break;

      case DivisionMethod.unequal:
        if (customAmounts == null || customAmounts.length != involvedMembers.length) {
          throw Exception('Custom amounts must be provided for unequal split');
        }
        if (customAmounts.fold<double>(0, (sum, amount) => sum + amount) != totalAmount) {
          throw Exception('Sum of custom amounts must equal total amount');
        }
        splits = Expense.createSplitsFromAmounts(involvedMembers, customAmounts);
        break;

      case DivisionMethod.percentage:
        if (percentages == null || percentages.length != involvedMembers.length) {
          throw Exception('Percentages must be provided for percentage split');
        }
        if (percentages.fold<double>(0, (sum, pct) => sum + pct) != 100) {
          throw Exception('Percentages must sum to 100');
        }
        splits = _splitByPercentage(totalAmount, involvedMembers, percentages);
        break;
    }

    // Update expense properties
    expense
      ..totalAmount = totalAmount
      ..divisionMethod = divisionMethod
      ..paidByMember = paidByMember
      ..splits = splits
      ..group = group
      ..description = description;

    if (expense.validateSplits()) {
      await expense.save();
      await _updateMemberBalances(expense);
    } else {
      throw Exception('Invalid splits: Total of splits does not match expense amount');
    }
  }

  static List<Expense> getAllExpenses() {
    final box = Hive.box<Expense>(expenseBoxName);
    return box.values.toList();
  }

  static List<Expense> getExpensesByGroup(Group group) {
    //final grpid=group.getGroupId();
    final box = Hive.box<Expense>(expenseBoxName);
    return box.values.where((expense) => expense.group?.id == group.id).toList();
  }

  static Future<void> deleteExpense(Expense expense) async {
    // Reverse the member balance updates
    await _reverseMemberBalances(expense);
    await expense.delete();
  }


  static String getGroupBalanceText(Member member, Group group) {
    double totalLent = 0.0;
    double totalOwed = 0.0;
    final expenses = getExpensesByGroup(group);

    for (var expense in expenses) {
      try {
        // When member is the payer
        if (expense.paidByMember.phone == member.phone) {
          // Get total amount paid for the expense
          double totalPaid = expense.totalAmount;

          // Find member's own share in this expense
          double ownShare = 0.0;
          final selfSplit = expense.splits
              .firstWhereOrNull((split) => split.member.phone == member.phone);
          if (selfSplit != null) {
            ownShare = selfSplit.amount;
          }

          // Amount lent is total paid minus own share
          totalLent += (totalPaid - ownShare);
        }

        // When member owes money (someone else paid)
        if (expense.paidByMember.phone != member.phone) {
          final memberSplit = expense.splits
              .firstWhereOrNull((split) => split.member.phone == member.phone);

          if (memberSplit != null) {
            totalOwed += memberSplit.amount;
          }
        }
      } catch (e) {
        print('Error processing expense: ${e.toString()}');
        continue; // Skip problematic expenses instead of failing
      }
    }

    // Handle potential floating point precision issues
    final netAmount = (totalLent - totalOwed).roundToDouble();

    // Use absolute value for negative amounts
    if (netAmount > 0.0) {
      return 'you get back ₹${netAmount.toStringAsFixed(2)}';
    } else if (netAmount < 0.0) {
      return 'you owe ₹${netAmount.abs().toStringAsFixed(2)}';
    } else {
      return 'all settled up';
    }
  }



  // static String getGroupBalanceText(Member member, Group group) {
  //   double totalLent = 0.0;
  //   double totalOwed = 0.0;
  //   final expenses = getExpensesByGroup(group);
  //
  //   for (var expense in expenses) {
  //     try {
  //       // When member is the payer
  //       if (expense.paidByMember.phone == member.phone) {
  //         // Calculate total amount lent to others (excluding self splits)
  //         final lentAmount = expense.splits
  //             .where((split) => split.member.phone != member.phone)
  //             .fold(0.0, (sum, split) => sum + (split.amount ?? 0.0));
  //         totalLent += lentAmount;
  //       }
  //
  //       // When member owes money
  //       final memberSplit = expense.splits.firstWhereOrNull((split) => split.member.id == member.id);
  //
  //       if (memberSplit != null && expense.paidByMember.id != member.id) {
  //         totalOwed += memberSplit.amount;
  //       }
  //     } catch (e) {
  //       print('Error processing expense: ${e.toString()}');
  //       continue; // Skip problematic expenses instead of failing
  //     }
  //   }
  //
  //   // Handle potential floating point precision issues
  //   final netAmount = (totalLent - totalOwed).roundToDouble();
  //
  //   // Use absolute value for negative amounts
  //   if (netAmount > 0.0) {
  //     return 'you get back ₹${netAmount.toStringAsFixed(2)}';
  //   } else if (netAmount < 0.0) {
  //     return 'you owe ₹${netAmount.abs().toStringAsFixed(2)}';
  //   } else {
  //     return 'all settled up';
  //   }
  // }

  // EXPENSE SPLITTING HELPERS
  static List<ExpenseSplit> _splitEqually(
    double totalAmount,
    List<Member> members,
  ) {
    final perPersonAmount = totalAmount / members.length;
    return members
        .map((member) => ExpenseSplit(
              member: member,
              amount: perPersonAmount,
              percentage: 100 / members.length,
            ))
        .toList();
  }

  static String getBalanceText(Member member) {
    final netWorth = getMemberNetWorth(member);
    return netWorth.summaryText;
  }

  static List<ExpenseSplit> _splitByPercentage(
    double totalAmount,
    List<Member> members,
    List<double> percentages,
  ) {
    return List.generate(
      members.length,
      (i) => ExpenseSplit(
        member: members[i],
        amount: (totalAmount * percentages[i]) / 100,
        percentage: percentages[i],
      ),
    );
  }

  static Future<void> _updateMemberBalances(Expense expense) async {
    final membersBox = Hive.box<Member>(memberBoxName);

    for (var split in expense.splits) {
      if (split.member.phone != expense.paidByMember.phone) {
        final member = membersBox.get(split.member.phone);
        if (member != null) {
          member.totalAmountOwedByMe += split.amount;
          await member.save();
        }
      }
    }
  }

  static Future<void> _reverseMemberBalances(Expense expense) async {
    final membersBox = Hive.box<Member>(memberBoxName);

    for (var split in expense.splits) {
      if (split.member.phone != expense.paidByMember.phone) {
        final member = membersBox.get(split.member.phone);
        if (member != null) {
          member.totalAmountOwedByMe -= split.amount;
          await member.save();
        }
      }
    }
  }

  static MemberNetWorth getMemberNetWorth(Member member) {
    final expenses = getAllExpenses();
    double totalLent = 0.0;
    double totalOwed = 0.0;

    // Track group-wise summaries
    Map<Object, ExpenseGroupSummary> groupSummaries = {};

    // Track category totals
    Map<String, double> categoryTotals = {};

    for (var expense in expenses) {
      try {
        double lentInExpense = 0.0;
        double owedInExpense = 0.0;

        // Calculate amount lent in this expense
        if (expense.paidByMember.phone == member.phone) {
          lentInExpense = expense.splits
              .where((split) => split.member.phone != member.phone)
              .fold(0.0, (sum, split) => sum + (split.amount ?? 0.0));
          totalLent += lentInExpense;

          // Track category
          final category = expense.category ?? 'Uncategorized';
          categoryTotals[category] = (categoryTotals[category] ?? 0.0) + expense.totalAmount;
        }

        // Calculate amount owed in this expense
        final memberSplit = expense.splits.firstWhereOrNull((split) => split.member.phone == member.phone);

        if (memberSplit != null && expense.paidByMember.phone != member.phone) {
          owedInExpense = memberSplit.amount;
          totalOwed += owedInExpense;
        }

        // Update group summary
        final groupKey = expense.group?.id ?? 'personal';
        final existingSummary = groupSummaries[groupKey];

        if (existingSummary == null) {
          groupSummaries[groupKey] = ExpenseGroupSummary(
            group: expense.group,
            amountLent: lentInExpense,
            amountOwed: owedInExpense,
            netAmount: lentInExpense - owedInExpense,
            expenseCount: 1,
          );
        } else {
          groupSummaries[groupKey] = ExpenseGroupSummary(
            group: expense.group,
            amountLent: existingSummary.amountLent + lentInExpense,
            amountOwed: existingSummary.amountOwed + owedInExpense,
            netAmount: existingSummary.netAmount + (lentInExpense - owedInExpense),
            expenseCount: existingSummary.expenseCount + 1,
          );
        }
      } catch (e) {
        print('Error processing expense: ${e.toString()}');
        continue;
      }
    }

    return MemberNetWorth(
      totalAmountLent: totalLent,
      totalAmountOwed: totalOwed,
      netWorth: totalLent - totalOwed,
      groupSummaries: groupSummaries.values.toList(),
      categoryTotals: categoryTotals,
    );
  }
}

class MemberNetWorth {
  final double totalAmountLent;
  final double totalAmountOwed;
  final double netWorth;
  final List<ExpenseGroupSummary> groupSummaries;
  final Map<String, double> categoryTotals;

  MemberNetWorth({
    required this.totalAmountLent,
    required this.totalAmountOwed,
    required this.netWorth,
    required this.groupSummaries,
    required this.categoryTotals,
  });

  String get summaryText {
    if (netWorth > 0) {
      return 'Overall, you get back ₹${netWorth.toStringAsFixed(2)}';
    } else if (netWorth < 0) {
      return 'Overall, you owe ₹${(-netWorth).toStringAsFixed(2)}';
    }
    return 'All settled up';
  }
}

class ExpenseGroupSummary {
  final Group? group;
  final double amountLent;
  final double amountOwed;
  final double netAmount;
  final int expenseCount;

  ExpenseGroupSummary({
    required this.group,
    required this.amountLent,
    required this.amountOwed,
    required this.netAmount,
    required this.expenseCount,
  });

  String get groupName => group?.groupName ?? 'Personal Expenses';
}
