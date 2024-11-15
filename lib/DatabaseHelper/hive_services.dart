import 'dart:math';

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
    await group.delete();
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
        splits = _splitByAmount(involvedMembers, customAmounts);
        break;
      case DivisionMethod.percentage:
        if (percentages == null || percentages.length != involvedMembers.length) {
          throw Exception('Percentages must be provided for percentage split');
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

    if (_validateSplits(expense)) {
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
    // Reverse the previous balance updates
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
        splits = _splitByAmount(involvedMembers, customAmounts);
        break;
      case DivisionMethod.percentage:
        if (percentages == null || percentages.length != involvedMembers.length) {
          throw Exception('Percentages must be provided for percentage split');
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

    if (_validateSplits(expense)) {
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
    return box.values.where((expense) => expense.group?.groupName == group.groupName).toList();
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
      if (expense.paidByMember.phone == member.phone) {
        totalLent += expense.splits
            .where((split) => split.member.phone != member.phone)
            .fold(0.0, (sum, split) => sum + split.amount);
      }

      var memberSplit = expense.splits
          .where((split) => split.member.phone == member.phone)
          .firstOrNull;
      if (memberSplit != null && expense.paidByMember.phone != member.phone) {
        totalOwed += memberSplit.amount;
      }
    }

    final netAmount = totalLent - totalOwed;

    if (netAmount > 0) {
      return 'you lent ₹${netAmount.toStringAsFixed(1)}';
    } else if (netAmount < 0) {
      return 'you owe ₹${(-netAmount).toStringAsFixed(1)}';
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
    double totalLent = 0.0;
    double totalOwed = 0.0;
    final expenses = getAllExpenses();

    for (var expense in expenses) {
      // If member is the payer
      if (expense.paidByMember.phone == member.phone) {
        totalLent += expense.splits
            .where((split) => split.member.phone != member.phone)
            .fold(0.0, (sum, split) => sum + split.amount);
      }

      // If member owes money
      var memberSplit = expense.splits
          .where((split) => split.member.phone == member.phone)
          .firstOrNull;
      if (memberSplit != null && expense.paidByMember.phone != member.phone) {
        totalOwed += memberSplit.amount;
      }
    }

    final netAmount = totalLent - totalOwed;

    if (netAmount > 0) {
      return 'you lent ₹${netAmount.toStringAsFixed(1)}';
    } else if (netAmount < 0) {
      return 'you owe ₹${(-netAmount).toStringAsFixed(1)}';
    } else {
      return 'all settled up';
    }
  }
  static List<ExpenseSplit> _splitByAmount(
    List<Member> members,
    List<double> amounts,
  ) {
    return List.generate(
      members.length,
      (i) => ExpenseSplit(
        member: members[i],
        amount: amounts[i],
        percentage: null,
      ),
    );
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

  static bool _validateSplits(Expense expense) {
    double totalSplitAmount = expense.splits.fold(0, (sum, split) => sum + split.amount);
    return (totalSplitAmount - expense.totalAmount).abs() < 0.01;
  }

  static Future<void> _updateMemberBalances(Expense expense) async {
    // Get reference to the members box
    final membersBox = Hive.box<Member>(memberBoxName);

    for (var split in expense.splits) {
      if (split.member.key != expense.paidByMember.key) {
        // Get fresh reference to the member from the box
        final member = membersBox.get(split.member.key);
        if (member != null) {
          member.totalAmountOwedByMe += split.amount;
          await member.save();
        }
      }
    }
  }

  static Future<void> _reverseMemberBalances(Expense expense) async {
    final membersBox = Hive.box<Member>('members');

    // Reverse splits for non-paying members
    for (var split in expense.splits) {
      if (split.member.key != expense.paidByMember.key) {
        // Get fresh reference to the member from box
        final member = membersBox.get(split.member.key);
        if (member != null) {
          member.totalAmountOwedByMe -= split.amount;
          await member.save();
        }
      }
    }

    // Update the payer's balance
    final payer = membersBox.get(expense.paidByMember.key);
    if (payer != null) {
      payer.totalAmountOwedByMe += expense.totalAmount;
      await payer.save();
    }
  }

  // SETTLEMENT CALCULATIONS
  static List<SettlementTransaction> calculateSettlements(List<Member> members) {
    Map<String, double> balances = {};
    final expenses = getAllExpenses();

    // Calculate net balances for each member
    for (var expense in expenses) {
      String payerKey = expense.paidByMember.key.toString();
      balances[payerKey] = (balances[payerKey] ?? 0) + expense.totalAmount;

      for (var split in expense.splits) {
        String memberKey = split.member.key.toString();
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

  // ___________________________________________________________________________________

  // FILTERING AND ANALYTICS
  static List<Expense> getExpensesByDateRange(DateTime start, DateTime end) {
    final expenses = getAllExpenses();
    return expenses.where((expense) => expense.createdAt.isAfter(start) && expense.createdAt.isBefore(end)).toList();
  }

  static Map<String, double> getCategoryWiseExpenses(Group group) {
    final expenses = getExpensesByGroup(group);
    Map<String, double> categoryExpenses = {};

    for (var expense in expenses) {
      final category = expense.category ?? 'Uncategorized';
      categoryExpenses[category] = (categoryExpenses[category] ?? 0) + expense.totalAmount;
    }

    return categoryExpenses;
  }

  static Map<DateTime, double> getMonthlyExpenses(Group? group) {
    final expenses = group != null ? getExpensesByGroup(group) : getAllExpenses();
    Map<DateTime, double> monthlyExpenses = {};

    for (var expense in expenses) {
      final monthYear = DateTime(
        expense.createdAt.year,
        expense.createdAt.month,
        1,
      );
      monthlyExpenses[monthYear] = (monthlyExpenses[monthYear] ?? 0) + expense.totalAmount;
    }

    return monthlyExpenses;
  }

  // MEMBER ANALYTICS
  static Map<Member, MemberStatistics> getMemberStatistics(Group? group) {
    final expenses = group != null ? getExpensesByGroup(group) : getAllExpenses();
    Map<Member, MemberStatistics> statistics = {};

    for (var expense in expenses) {
      // Update payer statistics
      statistics.putIfAbsent(
        expense.paidByMember,
        () => MemberStatistics(),
      );
      statistics[expense.paidByMember]!.totalPaid += expense.totalAmount;
      statistics[expense.paidByMember]!.expensesPaid++;

      // Update participant statistics
      for (var split in expense.splits) {
        statistics.putIfAbsent(
          split.member,
          () => MemberStatistics(),
        );
        statistics[split.member]!.totalOwed += split.amount;
        statistics[split.member]!.expensesParticipated++;
      }
    }

    return statistics;
  }

  // EXPENSE CATEGORIES
  static Future<void> addExpenseCategory(Group group, String category) async {
    if (group.categories == null) {
      group.categories = [];
    }
    if (!group.categories!.contains(category)) {
      group.categories!.add(category);
      await updateGroup(group);
    }
  }

  static Future<void> removeExpenseCategory(Group group, String category) async {
    if (group.categories?.contains(category) ?? false) {
      group.categories!.remove(category);
      await updateGroup(group);
    }
  }

  // SIMPLIFIED SETTLEMENT
  static List<SettlementTransaction> getSimplifiedSettlements(Group group) {
    final members = group.members;
    final expenses = getExpensesByGroup(group);

    // Calculate net balances for each member
    Map<Member, double> balances = {};
    for (var member in members) {
      balances[member] = 0;
    }

    // Calculate initial balances
    for (var expense in expenses) {
      balances[expense.paidByMember] = (balances[expense.paidByMember] ?? 0) + expense.totalAmount;

      for (var split in expense.splits) {
        balances[split.member] = (balances[split.member] ?? 0) - split.amount;
      }
    }

    List<SettlementTransaction> settlements = [];
    var sortedMembers = balances.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // Generate settlement transactions
    while (sortedMembers.length >= 2) {
      var creditor = sortedMembers.first;
      var debtor = sortedMembers.last;

      double amount = min(-debtor.value, creditor.value);
      if (amount > 0.01) {
        settlements.add(SettlementTransaction(
          from: debtor.key,
          to: creditor.key,
          amount: amount,
        ));
      }

      // Update balances and remove settled members
      if ((creditor.value - amount).abs() < 0.01) {
        sortedMembers.removeAt(0);
      } else {
        sortedMembers[0] = MapEntry(
          creditor.key,
          creditor.value - amount,
        );
      }

      if ((debtor.value + amount).abs() < 0.01) {
        sortedMembers.removeLast();
      } else {
        sortedMembers[sortedMembers.length - 1] = MapEntry(
          debtor.key,
          debtor.value + amount,
        );
      }
    }

    return settlements;
  }

  // EXPENSE REMINDERS
  static List<ExpenseReminder> getPendingSettlements(Member member) {
    final expenses = getExpensesByMember(member);
    List<ExpenseReminder> reminders = [];

    for (var expense in expenses) {
      if (expense.paidByMember.key != member.key) {
        double amountOwed = expense.getAmountForMember(member);
        if (amountOwed > 0) {
          reminders.add(ExpenseReminder(
            expense: expense,
            amount: amountOwed,
            toMember: expense.paidByMember,
            fromMember: member,
            date: expense.createdAt,
          ));
        }
      }
    }

    return reminders;
  }

  // GROUP STATISTICS
  static GroupStatistics getGroupStatistics(Group group) {
    final expenses = getExpensesByGroup(group);
    final monthlyExpenses = getMonthlyExpenses(group);
    final categoryExpenses = getCategoryWiseExpenses(group);
    final memberStats = getMemberStatistics(group);

    return GroupStatistics(
      totalExpenses: expenses.fold(0, (sum, exp) => sum + exp.totalAmount),
      averageExpenseAmount:
          expenses.isEmpty ? 0 : expenses.fold(0.0, (sum, exp) => sum + exp.totalAmount) / expenses.length,
      monthlyExpenses: monthlyExpenses,
      categoryExpenses: categoryExpenses,
      memberStatistics: memberStats,
      expenseCount: expenses.length,
      activeMembers: group.members.length,
      mostActiveCategory: categoryExpenses.entries.reduce((a, b) => a.value > b.value ? a : b).key,
      mostActivePayer: memberStats.entries.reduce((a, b) => a.value.totalPaid > b.value.totalPaid ? a : b).key,
    );
  }
}

// Settlement Transaction class
class SettlementTransaction {
  final Member from;
  final Member to;
  final double amount;

  SettlementTransaction({
    required this.from,
    required this.to,
    required this.amount,
  });
}
// Additional Classes for Analytics

class MemberStatistics {
  double totalPaid;
  double totalOwed;
  int expensesPaid;
  int expensesParticipated;

  MemberStatistics({
    this.totalPaid = 0,
    this.totalOwed = 0,
    this.expensesPaid = 0,
    this.expensesParticipated = 0,
  });

  double get netBalance => totalPaid - totalOwed;
}

class GroupStatistics {
  final double totalExpenses;
  final double averageExpenseAmount;
  final Map<DateTime, double> monthlyExpenses;
  final Map<String, double> categoryExpenses;
  final Map<Member, MemberStatistics> memberStatistics;
  final int expenseCount;
  final int activeMembers;
  final String mostActiveCategory;
  final Member mostActivePayer;

  GroupStatistics({
    required this.totalExpenses,
    required this.averageExpenseAmount,
    required this.monthlyExpenses,
    required this.categoryExpenses,
    required this.memberStatistics,
    required this.expenseCount,
    required this.activeMembers,
    required this.mostActiveCategory,
    required this.mostActivePayer,
  });
}

class ExpenseReminder {
  final Expense expense;
  final double amount;
  final Member toMember;
  final Member fromMember;
  final DateTime date;

  ExpenseReminder({
    required this.expense,
    required this.amount,
    required this.toMember,
    required this.fromMember,
    required this.date,
  });
}
