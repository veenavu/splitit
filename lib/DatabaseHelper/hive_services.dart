import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';

import '../modelClass/models.dart';

class ExpenseManagerService {
  static const String profileBoxName = 'profiles';
  static const String groupBoxName = 'groups';
  static const String memberBoxName = 'members';
  static const String normalBox = 'normalBox';

  // Initialize Hive and Register Adapters
  static Future<void> initHive() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(ProfileAdapter());
    Hive.registerAdapter(GroupAdapter());
    Hive.registerAdapter(MemberAdapter());

    // Open Boxes
    await Hive.openBox<Profile>(profileBoxName);
    await Hive.openBox<Group>(groupBoxName);
    await Hive.openBox<Member>(memberBoxName);
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



    await member.delete();
  }



}

