import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../modelClass/models.dart';
import '../screens/dashboard/services/activityPage_services.dart';

class ExpenseManagerService {
  static const String profileBoxName = 'profiles';
  static const String groupBoxName = 'groups';
  static const String memberBoxName = 'members';
  static const String expenseBoxName = 'expenses';
  static const String normalBox = 'normalBox';
  static const String counterBoxName = 'counters';
  static const String settlementBoxName = 'settlements';
  static const String activityBoxName = 'activities';
  static const String transactionBoxName = 'transactions';

  //Add a Map to track open Boxes
  static final Map<String, Box> _openBoxes = {};

  // Initialize Hive and Register Adapters

  static Future<void> initHive() async {
    try {
      await Hive.initFlutter();
      // Register Adapters
      Hive.registerAdapter(ProfileAdapter());
      Hive.registerAdapter(GroupAdapter());
      Hive.registerAdapter(MemberAdapter());
      Hive.registerAdapter(DivisionMethodAdapter());
      Hive.registerAdapter(ExpenseAdapter());
      Hive.registerAdapter(ExpenseSplitAdapter());
      Hive.registerAdapter(SettlementAdapter()) ;
      Hive.registerAdapter(ExpenseSettlementAdapter());
      Hive.registerAdapter(ActivityAdapter()) ;
      Hive.registerAdapter(TransactionAdapter());
      Hive.registerAdapter(ExpenseStatusAdapter());

      // Open Boxes
      await Hive.openBox<Profile>(profileBoxName);
      await Hive.openBox<Group>(groupBoxName);
      await Hive.openBox<Member>(memberBoxName);
      await Hive.openBox<Expense>(expenseBoxName);
      await Hive.openBox<int>(counterBoxName);
      await Hive.openBox(normalBox);
      await Hive.openBox<Settlement>(settlementBoxName);
      await Hive.openBox<Activity>(activityBoxName);
      await Hive.openBox<Transaction>(transactionBoxName);
      await _validateDataIntegrity();
    } catch (e) {
      print(e);
    }
  }
  static Future<void> _validateDataIntegrity() async {
    try {
      final expensesBox = Hive.box<Expense>(expenseBoxName);
      final settlementsBox = Hive.box<Settlement>(settlementBoxName);

      // Validate expenses
      for (var expense in expensesBox.values) {
        if (!expense.isValid()) {
          print('Invalid expense found: ${expense.id}');
          // Handle invalid data (log, repair, or delete)
        }
      }

      // Validate settlements
      for (var settlement in settlementsBox.values) {
        if (!settlement.isValid()) {
          print('Invalid settlement found: ${settlement.id}');
          // Handle invalid data
        }
      }
    } catch (e) {
      print('Error validating data integrity: $e');
    }
  }

  static Future<void> recordPartialSettlement({
    required Member payer,
    required Member receiver,
    required double amount,
    required List<Expense> expenses,
  }) async {
    try {
      // Validate settlement amount
      double totalOwed = calculateTotalOwed(payer, receiver);
      if (amount > totalOwed) {
        throw Exception('Settlement amount exceeds total owed amount');
      }

      // Create settlement record
      List<ExpenseSettlement> expenseSettlements = [];
      double remainingAmount = amount;

      for (var expense in expenses) {
        if (remainingAmount <= 0) break;

        double unsettledAmount = calculateUnsettledAmount(expense, payer);
        if (unsettledAmount <= 0) continue;

        double settleAmount = unsettledAmount < remainingAmount ?
        unsettledAmount : remainingAmount;

        expenseSettlements.add(ExpenseSettlement(
          expense: expense,
          settledAmount: settleAmount,
        ));

        // Update expense
        expense.addSettlement(Settlement(
          payer: payer,
          receiver: receiver,
          amount: settleAmount,
          expenseSettlements: [expenseSettlements.last],
        ));

        remainingAmount -= settleAmount;
      }

      // Create and save settlement record
      final settlement = Settlement(
        payer: payer,
        receiver: receiver,
        amount: amount,
        expenseSettlements: expenseSettlements,
        status: remainingAmount > 0 ? 'partial' : 'complete',
        remainingAmount: remainingAmount,
      );

      final settlementBox = Hive.box<Settlement>(settlementBoxName);
      await settlementBox.add(settlement);

      // Create transaction record
      final transaction = Transaction(
        type: 'settlement',
        amount: amount,
        payer: payer,
        receiver: receiver,
        timestamp: DateTime.now(),
        description: 'Settlement payment',
      );

      final transactionBox = Hive.box<Transaction>(transactionBoxName);
      await transactionBox.add(transaction);

      // Update member balances
      await _updateBalancesAfterSettlement(payer, receiver, amount);
      await recalculateAllBalances();

    } catch (e) {
      print('Error recording settlement: $e');
      rethrow;
    }
  }


  static Future<void> _updateBalancesAfterSettlement(
      Member payer,
      Member receiver,
      double amount,
      ) async {
    try {
      final membersBox = Hive.box<Member>(memberBoxName);
      final groupsBox = Hive.box<Group>(groupBoxName);

      // Update payer's balance
      final payerMember = membersBox.get(payer.phone);
      if (payerMember != null) {
        payerMember.totalAmountOwedByMe -= amount;
        await payerMember.save();
      }

      // Update receiver's balance
      final receiverMember = membersBox.get(receiver.phone);
      if (receiverMember != null) {
        receiverMember.totalAmountOwedByMe += amount;
        await receiverMember.save();
      }

      // Update group balances for all affected groups
      for (var group in groupsBox.values) {
        if (group.members.any((m) => m.phone == payer.phone) &&
            group.members.any((m) => m.phone == receiver.phone)) {
          // Update group member balances
          for (var member in group.members) {
            if (member.phone == payer.phone) {
              member.balancesByGroup[group.id.toString()] =
                  (member.balancesByGroup[group.id.toString()] ?? 0.0) - amount;
            } else if (member.phone == receiver.phone) {
              member.balancesByGroup[group.id.toString()] =
                  (member.balancesByGroup[group.id.toString()] ?? 0.0) + amount;
            }
          }
          await group.save();
        }
      }
    } catch (e) {
      print('Error updating balances after settlement: $e');
      rethrow;
    }
  }


  static Future<void> recalculateAllBalances() async {
    try {
      final membersBox = Hive.box<Member>(memberBoxName);
      final groupsBox = Hive.box<Group>(groupBoxName);
      final expensesBox = Hive.box<Expense>(expenseBoxName);
      final settlementsBox = Hive.box<Settlement>(settlementBoxName);

      // Reset all balances
      for (var member in membersBox.values) {
        member.totalAmountOwedByMe = 0.0;
        member.balancesByGroup.clear();
        await member.save();
      }

      // Recalculate from expenses
      for (var expense in expensesBox.values) {
        for (var split in expense.splits) {
          if (split.member.phone != expense.paidByMember.phone) {
            final member = membersBox.get(split.member.phone);
            if (member != null) {
              member.totalAmountOwedByMe += split.amount;
              if (expense.group != null) {
                member.balancesByGroup[expense.group!.id.toString()] =
                    (member.balancesByGroup[expense.group!.id.toString()] ?? 0.0) + split.amount;
              }
              await member.save();
            }
          }
        }
      }

      // Apply settlements
      for (var settlement in settlementsBox.values) {
        final payer = membersBox.get(settlement.payer.phone);
        final receiver = membersBox.get(settlement.receiver.phone);

        if (payer != null) {
          payer.totalAmountOwedByMe -= settlement.amount;
          await payer.save();
        }

        if (receiver != null) {
          receiver.totalAmountOwedByMe += settlement.amount;
          await receiver.save();
        }
      }

      // Update group balances
      for (var group in groupsBox.values) {
        await group.save();
      }
    } catch (e) {
      print('Error recalculating balances: $e');
      rethrow;
    }
  }



  static double calculateTotalOwed(Member payer, Member receiver) {
    double total = 0.0;

    // Calculate from expenses
    final expenses = getAllExpenses().where((expense) =>
    (expense.paidByMember.phone == receiver.phone &&
        expense.splits.any((split) => split.member.phone == payer.phone)) ||
        (expense.paidByMember.phone == payer.phone &&
            expense.splits.any((split) => split.member.phone == receiver.phone))
    );

    for (var expense in expenses) {
      if (expense.paidByMember.phone == receiver.phone) {
        final payerSplit = expense.splits.firstWhere(
              (split) => split.member.phone == payer.phone,
          orElse: () => ExpenseSplit(member: payer, amount: 0),
        );
        total += payerSplit.amount;
      }
    }

    // Subtract existing settlements
    final settlements = Hive.box<Settlement>(settlementBoxName).values.where(
            (settlement) => settlement.payer.phone == payer.phone &&
            settlement.receiver.phone == receiver.phone
    );

    total -= settlements.fold(0.0, (sum, settlement) => sum + settlement.amount);

    return total;
  }

  // Add method to get transaction history between members
  static List<Transaction> getTransactionHistory(Member member1, Member member2) {
    final transactionBox = Hive.box<Transaction>(transactionBoxName);

    return transactionBox.values.where((transaction) =>
    (transaction.payer.phone == member1.phone &&
        transaction.receiver.phone == member2.phone) ||
        (transaction.payer.phone == member2.phone &&
            transaction.receiver.phone == member1.phone)
    ).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static double calculateUnsettledAmount(Expense expense, Member member) {
    if (!expense.splits.any((split) => split.member.phone == member.phone)) {
      return 0.0;
    }

    final split = expense.splits.firstWhere(
            (split) => split.member.phone == member.phone
    );

    return split.amount - expense.settlements.where(
            (settlement) => settlement.payer.phone == member.phone
    ).fold(0.0, (sum, settlement) => sum + settlement.amount);
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

      // Get current user
      final currentUserPhone = Hive.box(normalBox).get("mobile");
      final currentUser = getProfileByPhone(currentUserPhone);

      if (currentUser != null) {
        // Log group creation activity
        await ActivityService.logGroupCreated(
            group,
            Member(
                name: currentUser.name,
                phone: currentUser.phone,
                imagePath: currentUser.imagePath
            )
        );
      }
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
    try {
      final box = Hive.box<Group>(groupBoxName);
      int? index;

      // Find the index of the group in the box
      for (int i = 0; i < box.length; i++) {
        if (box.getAt(i)?.id == group.id) {
          index = i;
          break;
        }
      }

      if (index != null) {
        // Get the old group data for comparison
        final oldGroup = box.getAt(index);

        // Get current user
        final currentUserPhone = Hive.box(normalBox).get("mobile");
        final currentUser = getProfileByPhone(currentUserPhone);

        if (currentUser != null && oldGroup != null) {
          final editor = Member(
              name: currentUser.name,
              phone: currentUser.phone,
              imagePath: currentUser.imagePath
          );

          // Check for name changes
          if (oldGroup.groupName != group.groupName) {
            await ActivityService.logGroupNameChanged(
                group,
                oldGroup.groupName,
                group.groupName,
                editor
            );
          }

          // Check for type changes
          if (oldGroup.category != group.category) {
            await ActivityService.logGroupTypeChanged(
                group,
                oldGroup.category,
                group.category,
                editor
            );
          }

          // Check for member changes
          Set<String> oldMembers = oldGroup.members.map((m) => m.phone).toSet();
          Set<String> newMembers = group.members.map((m) => m.phone).toSet();

          // Log removed members
          for (var oldMember in oldGroup.members) {
            if (!newMembers.contains(oldMember.phone)) {
              await ActivityService.logMemberRemoved(
                  group,
                  oldMember,
                  editor
              );
            }
          }

          // Log added members
          for (var newMember in group.members) {
            if (!oldMembers.contains(newMember.phone)) {
              await ActivityService.logMemberAdded(
                  group,
                  newMember,
                  editor
              );
            }
          }
        }

        // Update the group
        await box.putAt(index, group);
      } else {
        throw Exception('Group not found in database');
      }
    } catch (e) {
      print('Error updating group: $e');
      throw Exception('Failed to update group: ${e.toString()}');
    }
  }

  static Future<void> deleteGroup(Group group) async {
    try {
      // Get current user before deleting
      final currentUserPhone = Hive.box(normalBox).get("mobile");
      final currentUser = getProfileByPhone(currentUserPhone);

      // Delete expenses first
      final expenses = getExpensesByGroup(group);
      for (var expense in expenses) {
        await deleteExpense(expense);
      }

      // Log the deletion if we have a current user
      if (currentUser != null) {
        await ActivityService.logGroupDeleted(
            group,
            Member(
                name: currentUser.name,
                phone: currentUser.phone,
                imagePath: currentUser.imagePath
            )
        );
      }

      // Finally delete the group
      await group.delete();
    } catch (e) {
      throw Exception('Failed to delete group: ${e.toString()}');
    }
  }

  static List<Group> getGroupsYouOwe(Member member) {
    final allGroups = getAllGroups();
    return allGroups.where((group) {
      // Get group balance
      final balance = getGroupBalance(group, member);
      // Return true if you owe money in this group (negative balance)
      return balance < 0;
    }).toList();
  }

  static List<Group> getGroupsThatOweYou(Member member) {
    final allGroups = getAllGroups();
    return allGroups.where((group) {
      // Get group balance
      final balance = getGroupBalance(group, member);
      // Return true if others owe you money in this group (positive balance)
      return balance > 0;
    }).toList();
  }

// Helper function to get amount owed/to be received for a group
  static double getGroupBalance(Group group, Member member) {
    final expenses = getExpensesByGroup(group);
    double totalLent = 0.0;
    double totalOwed = 0.0;

    // Calculate expense-based balances
    for (var expense in expenses) {
      if (expense.paidByMember.phone == member.phone) {
        double ownShare = 0.0;
        final selfSplit = expense.splits.firstWhereOrNull(
                (split) => split.member.phone == member.phone
        );
        if (selfSplit != null) {
          ownShare = selfSplit.amount;
        }
        totalLent += (expense.totalAmount - ownShare);
      }

      if (expense.paidByMember.phone != member.phone) {
        final memberSplit = expense.splits.firstWhereOrNull(
                (split) => split.member.phone == member.phone
        );
        if (memberSplit != null) {
          totalOwed += memberSplit.amount;
        }
      }
    }

    // Adjust for settlements, considering only the portions related to this group
    final settlements = Hive.box<Settlement>(settlementBoxName).values.where(
            (settlement) =>
        (settlement.payer.phone == member.phone ||
            settlement.receiver.phone == member.phone) &&
            settlement.expenseSettlements.any((es) => es.expense.group?.id == group.id)
    );

    for (var settlement in settlements) {
      // Calculate portion of settlement that applies to this group
      double groupSettlementAmount = settlement.expenseSettlements
          .where((es) => es.expense.group?.id == group.id)
          .fold(0.0, (sum, es) => sum + es.settledAmount);

      if (settlement.payer.phone == member.phone) {
        totalOwed -= groupSettlementAmount;
      } else if (settlement.receiver.phone == member.phone) {
        totalLent -= groupSettlementAmount;
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
    try {
      List<ExpenseSplit> splits;
      switch (divisionMethod) {
        case DivisionMethod.equal:
          splits = _splitEqually(totalAmount, involvedMembers);
          break;
        case DivisionMethod.unequal:
          if (customAmounts == null || customAmounts.length != involvedMembers.length) {
            throw Exception('Custom amounts must be provided for unequal split');
          }
          splits = Expense.createSplitsFromAmounts(involvedMembers, customAmounts);
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

      if (expense.validateSplits()) {
        final box = Hive.box<Expense>(expenseBoxName);
        await box.add(expense);
        await _updateMemberBalances(expense);

        // Log expense creation activity
        await ActivityService.logExpenseAdded(
          expense,
          paidByMember,
        );

      } else {
        throw Exception('Invalid splits: Total of splits does not match expense amount');
      }
    } catch (e) {
      throw Exception('Failed to create expense: ${e.toString()}');
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
    try {
      // Store old values for activity logging
      final oldAmount = expense.totalAmount;
      final oldPayer = expense.paidByMember;
      final oldDescription = expense.description;

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
          splits = Expense.createSplitsFromAmounts(involvedMembers, customAmounts);
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

      if (expense.validateSplits()) {
        await expense.save();
        await _updateMemberBalances(expense);

        // Build changes description for activity log
        List<String> changes = [];
        if (oldAmount != totalAmount) {
          changes.add('amount changed from ₹${oldAmount.toStringAsFixed(2)} to ₹${totalAmount.toStringAsFixed(2)}');
        }
        if (oldPayer.phone != paidByMember.phone) {
          changes.add('payer changed from ${oldPayer.name} to ${paidByMember.name}');
        }
        if (oldDescription != description) {
          changes.add('description updated');
        }

        if (changes.isNotEmpty) {
          // Log expense update activity
          await ActivityService.logExpenseEdited(
            expense,
            paidByMember,
            changes.join(', '),
          );
        }

      } else {
        throw Exception('Invalid splits: Total of splits does not match expense amount');
      }
    } catch (e) {
      throw Exception('Failed to update expense: ${e.toString()}');
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
    try {
      // Get current user before deleting
      final box = Hive.box(normalBox);
      final currentUserPhone = box.get("mobile");
      final currentUser = getProfileByPhone(currentUserPhone);

      if (currentUser != null) {
        // Log expense deletion activity
        await ActivityService.logExpenseDeleted(
          expense,
          Member(
            name: currentUser.name,
            phone: currentUser.phone,
          ),
        );
      }

      // Reverse the member balance updates
      await _reverseMemberBalances(expense);
      await expense.delete();
    } catch (e) {
      throw Exception('Failed to delete expense: ${e.toString()}');
    }
  }

  static String getGroupBalanceText(Member member, Group group) {
    final balance = calculateGroupBalance(group, member);

    if (balance.netAmount > 0) {
      return 'you get back ₹${balance.netAmount.toStringAsFixed(2)}';
    } else if (balance.netAmount < 0) {
      return 'you owe ₹${(-balance.netAmount).toStringAsFixed(2)}';
    }
    return 'all settled up';
  }


  static String getBalanceText(Member member) {
    final allGroups = getAllGroups();
    double totalToReceive = 0.0;
    double totalToPayBack = 0.0;

    for (var group in allGroups) {
      final groupBalance = calculateGroupBalance(group, member);
      totalToReceive += groupBalance.amountToReceive;
      totalToPayBack += groupBalance.amountToPayBack;
    }

    final netAmount = totalToReceive - totalToPayBack;

    if (netAmount > 0) {
      return 'Overall, you get back ₹${netAmount.toStringAsFixed(2)}';
    } else if (netAmount < 0) {
      return 'Overall, you owe ₹${(-netAmount).toStringAsFixed(2)}';
    }
    return 'All settled up';
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


  static Future<void> updateBalancesAfterSettlement(Settlement settlement) async {
    try {
      // Update member balances
      final membersBox = Hive.box<Member>(memberBoxName);

      // Update payer's balance
      final payer = membersBox.get(settlement.payer.phone);
      if (payer != null) {
        payer.totalAmountOwedByMe -= settlement.amount;
        await payer.save();
      }

      // Update receiver's balance
      final receiver = membersBox.get(settlement.receiver.phone);
      if (receiver != null) {
        receiver.totalAmountOwedByMe += settlement.amount;
        await receiver.save();
      }

      // Update affected groups
      for (var expenseSettlement in settlement.expenseSettlements) {
        if (expenseSettlement.expense.group != null) {
          final group = expenseSettlement.expense.group!;
          await updateGroup(group);
        }
      }

    } catch (e) {
      print('Error updating balances after settlement: $e');
      throw Exception('Failed to update balances: ${e.toString()}');
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
          lentInExpense = expense.splits.where((split) => split.member.phone != member.phone).fold(0.0, (sum, split) => sum + (split.amount ?? 0.0));
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

  // In ExpenseManagerService class, add these methods:

  static Future<void> settleExpense(
      Expense expense,
      Member payer,
      Member receiver,
      double settledAmount
      ) async {
    try {
      // Find the split for the payer
      var payerSplit = expense.splits.firstWhere(
            (split) => split.member.phone == payer.phone,
        orElse: () => throw Exception('Payer split not found'),
      );

      // Reduce the amount in the split
      payerSplit.amount -= settledAmount;

      // Update the expense in the database
      await expense.save();

      // Update member balances
      await _updateMemberBalancesAfterSettlement(payer, receiver, settledAmount);

      // Log settlement activity
      await ActivityService.logSettlement(
        payer,
        receiver,
        settledAmount,
        expense.group != null ? [expense.group!] : null,
      );
    } catch (e) {
      throw Exception('Failed to settle expense: ${e.toString()}');
    }
  }

  static Future<void> _updateMemberBalancesAfterSettlement(
      Member payer,
      Member receiver,
      double amount
      ) async {
    final membersBox = Hive.box<Member>(memberBoxName);

    // Update payer's balance
    final payerMember = membersBox.get(payer.phone);
    if (payerMember != null) {
      payerMember.totalAmountOwedByMe -= amount;
      await payerMember.save();
    }

    // Update receiver's balance
    final receiverMember = membersBox.get(receiver.phone);
    if (receiverMember != null) {
      receiverMember.totalAmountOwedByMe += amount;
      await receiverMember.save();
    }
  }

// Add a method to record settlements with full expense history
  static Future<void> recordDetailedSettlement({
    required Member payer,
    required Member receiver,
    required double amount,
    required List<Expense> settledExpenses,
    required List<double> settledAmounts,
  }) async {
    try {
      // Create settlement record
      final settlement = Settlement(
        payer: payer,
        receiver: receiver,
        amount: amount,
        expenseSettlements: List.generate(
          settledExpenses.length,
              (i) => ExpenseSettlement(
            expense: settledExpenses[i],
            settledAmount: settledAmounts[i],
          ),
        ),
      );

      // Save settlement record
      final settlementBox = Hive.box<Settlement>(settlementBoxName);
      await settlementBox.add(settlement);

      // Update each expense and member balances
      for (var i = 0; i < settledExpenses.length; i++) {
        await settleExpense(
          settledExpenses[i],
          payer,
          receiver,
          settledAmounts[i],
        );
      }
    } catch (e) {
      throw Exception('Failed to record settlement: ${e.toString()}');
    }
  }
  static GroupBalance calculateGroupBalance(Group group, Member currentMember) {
    double amountToReceive = 0.0;
    double amountToPayBack = 0.0;

    // 1. Calculate from expenses first
    final groupExpenses = getExpensesByGroup(group);

    for (var expense in groupExpenses) {
      if (expense.paidByMember.phone == currentMember.phone) {
        // Current member paid - calculate what others owe
        double totalExpense = expense.totalAmount;
        double ownShare = expense.splits
            .firstWhere((split) => split.member.phone == currentMember.phone)
            .amount;
        amountToReceive += (totalExpense - ownShare);
      } else {
        // Someone else paid - find what current member owes
        var myShare = expense.splits
            .firstWhere(
              (split) => split.member.phone == currentMember.phone,
          orElse: () => ExpenseSplit(member: currentMember, amount: 0),
        );
        amountToPayBack += myShare.amount;
      }
    }

    // 2. Adjust for settlements
    final settlements = Hive.box<Settlement>(settlementBoxName).values.where(
            (settlement) =>
            settlement.expenseSettlements.any((es) => es.expense.group?.id == group.id)
    );

    for (var settlement in settlements) {
      double groupSettlementAmount = settlement.expenseSettlements
          .where((es) => es.expense.group?.id == group.id)
          .fold(0.0, (sum, es) => sum + es.settledAmount);

      if (settlement.payer.phone == currentMember.phone) {
        amountToPayBack = (amountToPayBack - groupSettlementAmount).clamp(0.0, double.infinity);
      } else if (settlement.receiver.phone == currentMember.phone) {
        amountToReceive = (amountToReceive - groupSettlementAmount).clamp(0.0, double.infinity);
      }
    }

    final netAmount = amountToReceive - amountToPayBack;

    return GroupBalance(
      amountToReceive: amountToReceive,
      amountToPayBack: amountToPayBack,
      netAmount: netAmount,
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
class GroupBalance {
  final double amountToReceive; // Amount others owe me
  final double amountToPayBack; // Amount I owe others
  final double netAmount;       // Net balance (positive means I get back, negative means I owe)

  GroupBalance({
    required this.amountToReceive,
    required this.amountToPayBack,
    required this.netAmount,
  });
}
