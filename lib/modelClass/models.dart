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
  }) : createdAt = createdAt ?? DateTime.now();
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
  // List<Expense> expenses;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  List<String>? categories;

  Group({
    required this.groupName,
    required this.groupImage,
    this.category,
    required this.members,
    // List<Expense>? expenses,
    this.categories,
    DateTime? createdAt,
  })  : createdAt = createdAt ?? DateTime.now();



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
