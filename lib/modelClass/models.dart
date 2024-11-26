import 'package:equatable/equatable.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
part 'models.g.dart';


// Profile Model
@HiveType(typeId: 0)
class Profile extends HiveObject with EquatableMixin {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? imagePath;

  @HiveField(3)
  String email;

  @HiveField(4)
  String phone;

  Profile({
    this.id,
    required this.name,
    this.imagePath,
    required this.email,
    required this.phone,
  });


  int? getProfileId(){
    return id;
  }

  @override
  // TODO: implement props
  List<Object?> get props => [name, imagePath, email, phone];
}

// Member Model
@HiveType(typeId: 1)
class Member extends HiveObject with EquatableMixin {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phone;

  @HiveField(3)
  String? imagePath;

  @HiveField(4)
  List<Group>? groupsIncluded;

  @HiveField(5)
  double totalAmountOwedByMe;

  @HiveField(6)
  DateTime createdAt;

  Member({
    this.id ,
    required this.name,
    required this.phone,
    this.imagePath,
    this.groupsIncluded,
    this.totalAmountOwedByMe = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Helper method to get member's expenses in a specific group
  List<Expense> getExpensesInGroup(Group group) {
    return group.expenses
        .where((expense) => expense.isMemberInvolved(this))
        .toList();
  }



  int? getMemberId(){
    return id;
  }

  // Helper method to get total amount spent in a group
  double getTotalSpentInGroup(Group group) {
    return group.expenses
        .where((expense) => expense.paidByMember.key == key)
        .fold(0.0, (sum, expense) => sum + expense.totalAmount);
  }

  @override
  List<Object?> get props => [name, phone, imagePath, groupsIncluded, totalAmountOwedByMe, createdAt];
}

// Group Model
@HiveType(typeId: 2)
class Group extends HiveObject with EquatableMixin{

  @HiveField(0)
  int? id;

  @HiveField(1)
  String groupName;

  @HiveField(2)
  String groupImage;

  @HiveField(3)
  String? category;

  @HiveField(4)
  List<Member> members;

  @HiveField(5)
  List<Expense> expenses;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  List<String>? categories;

  Group({
    this.id,
    required this.groupName,
    required this.groupImage,
    this.category,
    required this.members,
    List<Expense>? expenses,
    this.categories,
    DateTime? createdAt,
  })  : expenses = expenses ?? [],
        createdAt = createdAt ?? DateTime.now();

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
          orElse: () => ExpenseSplit( member: member, amount: 0))
          .amount;
      return sum + memberSplit;
    });

    return paid - owed;
  }
  int? getGroupId(){
    return id;
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

  @override
  List<Object?> get props => [
    groupName,
    groupImage,
    category,
    members,
    expenses,
    createdAt,
    categories
  ];
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
  int? id;

  @HiveField(1)
  Member member;

  @HiveField(2)
  double amount;

  @HiveField(3)
  double? percentage;

  ExpenseSplit({
    this.id,
    required this.member,
    required this.amount,
    this.percentage,
  });

  // Create a copy of ExpenseSplit with new values
  ExpenseSplit copyWith({
    Member? member,
    double? amount,
    double? percentage,
  }) {
    return ExpenseSplit(
      member: member ?? this.member,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
    );
  }
}

// Expense Model
@HiveType(typeId: 5)
class Expense extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  double totalAmount;

  @HiveField(2)
  DivisionMethod divisionMethod;

  @HiveField(3)
  Member paidByMember;

  @HiveField(4)
  List<ExpenseSplit> splits;

  @HiveField(5)
  Group? group;

  @HiveField(6)
  String description;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  String? category;

  @HiveField(9)
  String? note;

  @HiveField(10)
  List<String>? attachments;

  Expense({
    this.id,
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
  }) : createdAt = createdAt ?? DateTime.now();

  // Create splits from members and amounts
  static List<ExpenseSplit> createSplitsFromAmounts(
      List<Member> members,
      List<double> amounts,
      ) {
    if (members.length != amounts.length) {
      throw Exception('Members and amounts must have the same length');
    }

    return List.generate(
      members.length,
          (i) => ExpenseSplit(
        member: members[i],
        amount: amounts[i],

        percentage: null,
      ),
    );
  }

  // Validate splits total matches expense amount
  bool validateSplits() {
    double totalSplitAmount = splits.fold(0, (sum, split) => sum + split.amount);
    return (totalSplitAmount - totalAmount).abs() < 0.01;
  }

  // Get split for a specific member
  ExpenseSplit? getSplitForMember(Member member) {
    return splits.firstWhereOrNull((split) => split.member.key == member.key);
  }

  // Check if a member is involved
  bool isMemberInvolved(Member member) {
    return splits.any((split) => split.member.key == member.key) ||
        paidByMember.key == member.key;
  }

  // Update amounts for unequal split
  void updateUnequalSplits(List<Member> members, List<double> amounts) {
    if (divisionMethod != DivisionMethod.unequal) {
      throw Exception('Can only update amounts for unequal split');
    }

    splits = createSplitsFromAmounts(members, amounts);
    if (!validateSplits()) {
      throw Exception('Split amounts do not match total expense amount');
    }
  }
}

class SettlementTransaction {
  final int? sid;
  final Member from;
  final Member to;
  final double amount;

  SettlementTransaction({
     this.sid,
    required this.from,
    required this.to,
    required this.amount,
  });
}