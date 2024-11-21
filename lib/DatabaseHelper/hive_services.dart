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

  // Initialize Hive and Register Adapters
  static Future<void> initHive() async {
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
    await Hive.openBox(normalBox);
  }

  // PROFILE OPERATIONS
  static Future<void> saveProfile(Profile profile) async {
    final box = Hive.box<Profile>(profileBoxName);
    await box.add(profile);
  }

  static Profile? getProfile() {
    final box = Hive.box<Profile>(profileBoxName);
    return box.isNotEmpty ? box.getAt(0) : null;
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

  // GROUP OPERATIONS
  static Future<void> saveTheGroup(Group group) async {
    final box = Hive.box<Group>(groupBoxName);
    await box.add(group);
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

  static List<Group> searchGroups(String searchTerm) {
    if (searchTerm.isEmpty) {
      return getAllGroups();
    }

    final box = Hive.box<Group>(groupBoxName);
    final searchTermLower = searchTerm.toLowerCase();

    return box.values.where((group) => group.groupName.toLowerCase().contains(searchTermLower)).toList();
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

  // MEMBER OPERATIONS
  static Future<void> saveMember(Member member) async {
    final box = Hive.box<Member>(memberBoxName);
    await box.add(member);
  }

  static List<Member> getAllMembers() {
    final box = Hive.box<Member>(memberBoxName);
    return box.values.toList();
  }

  static Future<void> updateMember(Member member) async {
    await member.save();
  }

  static Future<void> deleteMember(Member member) async {
    // Remove member from all groups
    final groups = getAllGroups();
    for (var group in groups) {
      if (group.members.contains(member)) {
        group.members.remove(member);
        await group.save();
      }
    }

    // Handle expenses involving this member
    final expenses = getExpensesByMember(member);
    for (var expense in expenses) {
      await deleteExpense(expense);
    }
    await member.delete();
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
    final box = Hive.box<Expense>(expenseBoxName);
    return box.values
        .where((expense) => expense.group?.groupName.toLowerCase() == group.groupName.toLowerCase())
        .toList();
  }

  static List<Expense> getExpensesByMember(Member member) {
    final box = Hive.box<Expense>(expenseBoxName);
    return box.values.where((expense) => expense.isMemberInvolved(member)).toList();
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
          // Calculate total amount lent to others (excluding self splits)
          final lentAmount = expense.splits
              .where((split) => split.member.phone != member.phone)
              .fold(0.0, (sum, split) => sum + (split.amount ?? 0.0));
          totalLent += lentAmount;
        }

        // When member owes money
        final memberSplit = expense.splits.firstWhereOrNull((split) => split.member.phone == member.phone);

        if (memberSplit != null && expense.paidByMember.phone != member.phone) {
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

  // SETTLEMENT CALCULATIONS
  static List<SettlementTransaction> calculateSettlements(List<Member> members) {
    Map<String, double> balances = {};
    final expenses = getAllExpenses();

    // Calculate net balances for each member
    for (var expense in expenses) {
      String payerKey = expense.paidByMember.phone.toString();
      balances[payerKey] = (balances[payerKey] ?? 0) + expense.totalAmount;

      for (var split in expense.splits) {
        String memberKey = split.member.phone.toString();
        balances[memberKey] = (balances[memberKey] ?? 0) - split.amount;
      }
    }

    List<SettlementTransaction> settlements = [];
    var memberBalances = balances.entries.toList();

    while (memberBalances.length >= 2) {
      memberBalances.sort((a, b) => b.value.compareTo(a.value));

      var creditor = memberBalances.first;
      var debtor = memberBalances.last;

      double amount = min(-debtor.value, creditor.value);
      if (amount > 0.01) {
        settlements.add(SettlementTransaction(
          from: Hive.box<Member>(memberBoxName).get(int.parse(debtor.key))!,
          to: Hive.box<Member>(memberBoxName).get(int.parse(creditor.key))!,
          amount: amount,
        ));
      }

      if ((creditor.value - amount).abs() < 0.01) {
        memberBalances.removeAt(0);
      } else {
        memberBalances[0] = MapEntry(creditor.key, creditor.value - amount);
      }

      if ((debtor.value + amount).abs() < 0.01) {
        memberBalances.removeLast();
      } else {
        memberBalances[memberBalances.length - 1] = MapEntry(debtor.key, debtor.value + amount);
      }
    }

    return settlements;
  }

  // Get member balance summary
  static Map<Member, double> getMemberBalances() {
    final members = getAllMembers();
    Map<Member, double> balances = {};

    for (var member in members) {
      balances[member] = member.totalAmountOwedByMe;
    }

    return balances;
  }

  // Get group expense summary
  static Map<String, dynamic> getGroupExpenseSummary(Group group) {
    final expenses = getExpensesByGroup(group);
    double totalExpenses = 0;
    Map<Member, double> memberContributions = {};

    for (var expense in expenses) {
      totalExpenses += expense.totalAmount;
      memberContributions[expense.paidByMember] =
          (memberContributions[expense.paidByMember] ?? 0) + expense.totalAmount;
    }

    return {
      'totalExpenses': totalExpenses,
      'memberContributions': memberContributions,
    };
  }

  static MemberGroupExpense getMemberGroupExpense(Member member, Group group) {
    final expenses = getExpensesByGroup(group);
    double totalPaid = 0.0;
    double totalShare = 0.0;

    for (var expense in expenses) {
      // Calculate amount paid by member
      if (expense.paidByMember.phone == member.phone) {
        totalPaid += expense.totalAmount;
      }

      // Calculate member's share in expenses
      // Using firstWhereOrNull to safely handle cases where member isn't in splits
      final memberSplit = expense.splits.firstWhereOrNull((split) => split.member.phone == member.phone);
      if (memberSplit != null) {
        totalShare += memberSplit.amount;
      }
    }

    return MemberGroupExpense(
      member: member,
      group: group,
      totalPaid: totalPaid,
      totalShare: totalShare,
      netBalance: totalPaid - totalShare,
    );
  }

  static MemberNetWorth getMemberNetWorth(Member member) {
    final expenses = getAllExpenses();
    double totalLent = 0.0;
    double totalOwed = 0.0;

    // Track group-wise summaries
    Map<String, ExpenseGroupSummary> groupSummaries = {};

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
        final groupKey = expense.group?.groupName ?? 'personal';
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

class MemberGroupExpense {
  final Member member;
  final Group group;
  final double totalPaid; // Total amount paid by member
  final double totalShare; // Total share in all expenses
  final double netBalance; // Positive means others owe them, negative means they owe others

  const MemberGroupExpense({
    required this.member,
    required this.group,
    required this.totalPaid,
    required this.totalShare,
    required this.netBalance,
  });

  String get balanceText {
    if (netBalance > 0) {
      return 'Gets back ₹${netBalance.toStringAsFixed(2)}';
    } else if (netBalance < 0) {
      return 'Owes ₹${(-netBalance).toStringAsFixed(2)}';
    }
    return 'All settled';
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
