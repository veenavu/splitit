import 'package:hive/hive.dart';

part 'models.g.dart';

// Profile Model
@HiveType(typeId: 0)
class Profile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String? imagePath;

  @HiveField(2)
  String email;

  @HiveField(3)
  String phone;

  Profile({
    required this.name,
    this.imagePath,
    required this.email,
    required this.phone,
  });
}

// Member Model
@HiveType(typeId: 1)
class Member extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String phone;

  @HiveField(2)
  String? imagePath;

  @HiveField(3)
  List<Group>? groupsIncluded;

  @HiveField(4)
  double totalAmountOwedByMe;

  @HiveField(5)
  DateTime createdAt;

  Member({
    required this.name,
    required this.phone,
    this.imagePath,
    this.groupsIncluded,
    this.totalAmountOwedByMe = 0.0,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  // Helper method to get member's expenses in a specific group
  List<Expense> getExpensesInGroup(Group group) {
    return group.expenses
        .where((expense) => expense.isMemberInvolved(this))
        .toList();
  }

  // Helper method to get total amount spent in a group
  double getTotalSpentInGroup(Group group) {
    return group.expenses
        .where((expense) => expense.paidByMember.key == this.key)
        .fold(0.0, (sum, expense) => sum + expense.totalAmount);
  }
}

// Group Model
@HiveType(typeId: 2)
class Group extends HiveObject {
  @HiveField(0)
  String groupName;

  @HiveField(1)
  String groupImage;

  @HiveField(2)
  String? category;

  @HiveField(3)
  List<Member> members;

  @HiveField(4)
  List<Expense> expenses;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  List<String>? categories;

  Group({
    required this.groupName,
    required this.groupImage,
    this.category,
    required this.members,
    List<Expense>? expenses,
    this.categories,
    DateTime? createdAt,
  })  : this.expenses = expenses ?? [],
        this.createdAt = createdAt ?? DateTime.now();

  // Helper method to get total group expenses
  double get totalExpenses =>
      expenses.fold(0.0, (sum, expense) => sum + expense.totalAmount);

  // Helper method to get member's balance in the group
  double getMemberBalance(Member member) {
    double paid = expenses
        .where((e) => e.paidByMember.key == member.key)
        .fold(0.0, (sum, e) => sum + e.totalAmount);

    double owed = expenses.fold(0.0, (sum, expense) {
      var memberSplit = expense.splits
          .firstWhere((split) => split.member.key == member.key,
          orElse: () => ExpenseSplit(member: member, amount: 0))
          .amount;
      return sum + memberSplit;
    });

    return paid - owed;
  }

  // Helper method to add expense category
  void addCategory(String category) {
    categories ??= [];
    if (!categories!.contains(category)) {
      categories!.add(category);
    }
  }

  // Method to categorize the group's expense status
  String getGroupStatus(Member member) {
    if (expenses.isEmpty) {
      return "No Expense"; // No transactions in the group
    }

    double balance = getMemberBalance(member);

    if (balance == 0) {
      return "Settled"; // No balance, meaning all expenses are settled
    } else if (balance < 0) {
      return "Owed"; // The member owes money in the group
    } else {
      return "Lent"; // The member has lent money to others
    }
  }
}


// Division Method Enum
@HiveType(typeId: 3)
enum DivisionMethod {
  @HiveField(0)
  equal,

  @HiveField(1)
  unequal,

  @HiveField(2)
  percentage
}

// ExpenseSplit Model
@HiveType(typeId: 4)
class ExpenseSplit extends HiveObject {
  @HiveField(0)
  Member member;

  @HiveField(1)
  double amount;

  @HiveField(2)
  double? percentage;

  ExpenseSplit({
    required this.member,
    required this.amount,
    this.percentage,
  });
}

// Expense Model
@HiveType(typeId: 5)
class Expense extends HiveObject {
  @HiveField(0)
  double totalAmount;

  @HiveField(1)
  DivisionMethod divisionMethod;

  @HiveField(2)
  Member paidByMember;

  @HiveField(3)
  List<ExpenseSplit> splits;

  @HiveField(4)
  Group? group;

  @HiveField(5)
  String description;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  String? category;

  @HiveField(8)
  String? note;

  @HiveField(9)
  List<String>? attachments;

  Expense({
    required this.totalAmount,
    required this.divisionMethod,
    required this.paidByMember,
    required this.splits,
    this.group,
    required this.description,
    this.category,
    this.note,
    this.attachments,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  // Helper method to calculate amounts based on percentages
  void calculateSplitsByPercentage() {
    if (divisionMethod == DivisionMethod.percentage) {
      for (var split in splits) {
        if (split.percentage != null) {
          split.amount = (totalAmount * split.percentage!) / 100;
        }
      }
    }
  }

  // Validate if splits are correct
  bool validateSplits() {
    double totalSplitAmount = splits.fold(0, (sum, split) => sum + split.amount);
    return (totalSplitAmount - totalAmount).abs() < 0.01;
  }

  // Get amount owed by a specific member
  double getAmountForMember(Member member) {
    return splits
        .firstWhere((split) => split.member.key == member.key,
        orElse: () => ExpenseSplit(member: member, amount: 0))
        .amount;
  }

  // Check if a member is involved in this expense
  bool isMemberInvolved(Member member) {
    return splits.any((split) => split.member.key == member.key) ||
        paidByMember.key == member.key;
  }
}

// Statistics Models (Not stored in Hive)
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