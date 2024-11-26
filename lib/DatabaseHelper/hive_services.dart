import 'dart:math';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../modelClass/models.dart';

class ExpenseManagerService {
  static const String profileBoxName = 'profiles';
  static const String groupBoxName = 'groups';
  static const String memberBoxName = 'members';
  static const String expenseBoxName = 'expenses';
  static const String normalBox = 'normalBox';
  static const String groupIdBox = 'groupId';
  static const String memberIdBox = 'memberId';
  static const String profileIdBox = 'profileId';
  //Add a Map to track open Boxes
  static final Map<String, Box> _openBoxes = {};


  // Initialize Hive and Register Adapters
  static Future<void> initHive() async {
    await Hive.initFlutter();

    // Register Adapters (only if not already registered)
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ProfileAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(GroupAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(MemberAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DivisionMethodAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ExpenseAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(ExpenseSplitAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(MemberIdAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(GroupIdAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(ProfileIdAdapter());
    await _initializeHive();

  }

  static Future<void> _initializeHive() async {
    await Hive.openBox<Profile>(profileBoxName);
    await Hive.openBox<Group>(groupBoxName);
    await Hive.openBox<Member>(memberBoxName);
    await Hive.openBox<Expense>(expenseBoxName);
    await Hive.openBox(normalBox);
    await Hive.openBox<int>(groupIdBox);
    await Hive.openBox<int>(memberIdBox);
    await Hive.openBox<int>(profileIdBox);
  }

  static Future<Box> _openBox<T>(String boxName) async {
    try {
      if (_openBoxes.containsKey(boxName)) {
        return _openBoxes[boxName]!;
      }

      // Close the box if it's already open in Hive
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box<T>(boxName).close();
      }

      final box = await Hive.openBox<T>(boxName);
      _openBoxes[boxName] = box;
      return box;
    } catch (e) {
      // If there's an error, try to recover
      await Hive.deleteBoxFromDisk(boxName);
      final box = await Hive.openBox<T>(boxName);
      _openBoxes[boxName] = box;
      return box;
    }
  }
  static Future<Box> getBox(String boxName) async {
    if (!_openBoxes.containsKey(boxName)) {
      await _openBox(boxName);
    }
    return _openBoxes[boxName]!;
  }



  // PROFILE OPERATIONS
  static Future<void> saveProfile(Profile profile) async {
    final box = Hive.box<Profile>(profileBoxName);
    final pidBox=Hive.box<int>(profileIdBox);
    int nextId = await generateNextProfileId();
    profile.pid=nextId;
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


  // Add a method to get profile by ID
  static Profile? getProfileById(int pid) {
    final box = Hive.box<Profile>(profileBoxName);
    for (var profile in box.values) {
      if (profile.pid == pid) {
        return profile;
      }
    }
    return null;
  }

  static Future<void> updateProfile(Profile profile) async {
    await profile.save();
  }




  static Future<int> generateNextMemberId() async {

    final midBox = Hive.box(memberIdBox);
    int currentId = midBox.get('lastId', defaultValue: 0)!;
    int nextId = currentId + 1;
    await midBox.put('lastId', nextId);
    return nextId;
  }



  // Modified clearAllData method
  static Future<void> clearAllBoxesAndData() async {
    try {
      // Close all open boxes
      await Hive.close();

      // Clear the open boxes tracking map
      _openBoxes.clear();

      // Delete all boxes from disk
      await Future.wait([
        Hive.deleteBoxFromDisk(profileBoxName),
        Hive.deleteBoxFromDisk(groupBoxName),
        Hive.deleteBoxFromDisk(memberBoxName),
        Hive.deleteBoxFromDisk(expenseBoxName),
        Hive.deleteBoxFromDisk(normalBox),
        Hive.deleteBoxFromDisk(groupIdBox),
        Hive.deleteBoxFromDisk(memberIdBox),
        Hive.deleteBoxFromDisk(profileIdBox),
      ]);

      // Re-initialize Hive
      await initHive();
    } catch (e) {
      print('Error clearing Hive data: $e');
      rethrow;
    }
  }

  // GROUP OPERATIONS
  static Future<int> generateNextGroupId() async {

    final gidBox = Hive.box(groupIdBox);
    int currentId = gidBox.get('lastId', defaultValue: 0)!;
    int nextId = currentId + 1;
    await gidBox.put('lastId', nextId);
    return nextId;
  }


  // Modify existing group-related methods to use ID
  static Group? getGroupById(int groupId) {
    final box = Hive.box<Group>(groupBoxName);
    for (var group in box.values) {
      if (group.gid == groupId) {
        return group;
      }
    }
    return null;
  }



  static Future<void> saveTheGroup(Group group) async {
    try {
      final box = await getBox(groupBoxName) as Box<Group>;
      int nextId = await generateNextGroupId();
      group.gid = nextId;
      await box.add(group);
    } catch (e) {
      // Close and reopen the box if there's an error
      await _reopenBox<Group>(groupBoxName);
      throw Exception('Failed to save group: ${e.toString()}');
    }
  }

  static Future<void> _reopenBox<T>(String boxName) async {
    if (_openBoxes.containsKey(boxName)) {
      await _openBoxes[boxName]!.close();
      _openBoxes.remove(boxName);
    }
    await _openBox<T>(boxName);
  }


  static Future<int> generateNextProfileId() async {
    final pidBox = Hive.box<int>(profileIdBox);
    int currentId = pidBox.get('lastId', defaultValue: 0)!;
    int nextId = currentId + 1;
    await pidBox.put('lastId', nextId);
    return nextId;
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
        final memberSplit = expense.splits
            .firstWhereOrNull((split) => split.member.phone == member.phone);

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
        final memberSplit = expense.splits
            .firstWhereOrNull((split) => split.member.phone == member.phone);

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
      final memberSplit = expense.splits
          .firstWhereOrNull((split) => split.member.phone == member.phone);

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
    return box.values
        .where((expense) => expense.group?.gid == group.gid)
        .toList();
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
        if (expense.paidByMember.mid== member.mid) {
          // Calculate total amount lent to others (excluding self splits)
          final lentAmount = expense.splits
              .where((split) => split.member.mid!= member.mid)
              .fold(0.0, (sum, split) => sum + (split.amount ?? 0.0));
          totalLent += lentAmount;
        }

        // When member owes money
        final memberSplit = expense.splits.firstWhereOrNull((split) => split.member.mid == member.mid);

        if (memberSplit != null && expense.paidByMember.mid != member.mid) {
          totalOwed += memberSplit.amount;
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
        final groupKey = expense.group?.gid ?? 'personal';
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
