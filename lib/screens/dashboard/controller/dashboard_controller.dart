// DashboardController
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/routes/app_routes.dart';
import 'package:splitit/screens/dashboard/pages/activity_page.dart';
import 'package:splitit/screens/dashboard/pages/friends_page.dart';
import 'package:splitit/screens/dashboard/pages/group_list_page.dart';
import 'package:splitit/screens/dashboard/pages/profile_page.dart';

import 'activityPage_controller.dart';
import 'friendsPage_controller.dart';

class DashboardController extends GetxController {
  RxList<Group> groups = RxList<Group>.empty(growable: true);
  RxInt selectedIndex = 0.obs;
  Rxn<Profile> userProfile = Rxn<Profile>();
  RxString balanceText = "Loading...".obs;
  RxInt selectedFilter = 0.obs; // 0: All, 1: You owe, 2: Owes you
  RxList<Group> filteredGroups = RxList<Group>.empty(growable: true);
  var isLoading = false.obs; // Observable boolean for loading state

  final List<Widget> pages = [
    const GroupListPage(),
    GetBuilder<FriendsController>(
      init: FriendsController(),
      builder: (controller) => const FriendsPage(),
    ),
    GetBuilder<ActivityController>(
      init: ActivityController(),
      builder: (controller) => const ActivitiesPage(),
    ),
    const ProfilePage(),
  ];

  @override
  void onInit() {
    super.onInit();
    // First load the user profile
    getProfile().then((_) {
      // Then load groups after profile is loaded
      loadGroups();
      // Get balance text after groups are loaded
      getBalanceText();
    });
  }

  Future<void> loadGroups() async {
    isLoading.value = true;
    try {
      final allGroups = ExpenseManagerService.getAllGroups();
      groups.value = allGroups;
      applyFilter();
      if (Get.isRegistered<ActivityController>()) {
        Get.find<ActivityController>().loadActivities();
      }

      // Ensure balances are up to date
      for (var group in groups) {
        if (userProfile.value != null) {
          final currentMember = Member(
            name: userProfile.value!.name,
            phone: userProfile.value!.phone,
          );
          final balance = ExpenseManagerService.getGroupBalance(group, currentMember);
          // Update any cached balance information
        }
      }

      getBalanceText();
     // applyFilter();
      update();
    } catch (e) {
      print('Error loading groups: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilter() {
    if (userProfile.value == null) return;

    Member currentMember = Member(
      // id: userProfile.value!.getProfileId(),
      name: userProfile.value!.name,
      phone: userProfile.value!.phone,
    );

    switch (selectedFilter.value) {
      case 1: // You owe
        filteredGroups.value = ExpenseManagerService.getGroupsYouOwe(currentMember);
        break;
      case 2: // Owes you
        filteredGroups.value = ExpenseManagerService.getGroupsThatOweYou(currentMember);
        break;
      default: // All groups
        filteredGroups.value = groups;
        break;
    }
  }

  void changeFilter(int filterIndex) {
    selectedFilter.value = filterIndex;
    applyFilter();
  }

  // Get filtered groups with balance info
  List<Map<String, dynamic>> getGroupsWithBalance() {
    if (userProfile.value == null) return [];

    Member currentMember = Member(
      id: userProfile.value!.getProfileId(),
      name: userProfile.value!.name,
      phone: userProfile.value!.phone,
    );

    return filteredGroups.map((group) {
      double balance = ExpenseManagerService.getGroupBalance(group, currentMember);
      return {
        'group': group,
        'balance': balance,
        'balanceText': ExpenseManagerService.getGroupBalanceText(currentMember, group),
      };
    }).toList();
  }

  Future<void> getProfile() async {
    final box = Hive.box(ExpenseManagerService.normalBox);
    final phone = box.get("mobile");

    userProfile.value = ExpenseManagerService.getProfileByPhone(phone) ?? Profile(id: 0, name: "User", email: "noob", phone: "2173123");
  }

  void onStartGroup(VoidCallback? callback, BuildContext context) {
    Get.toNamed(Routes.addNewGroup)?.then((value) {
      callback?.call();
    });
  }

  void getBalanceText() {
    balanceText.value = userProfile.value != null
        ? ExpenseManagerService.getBalanceText(
            Member(
              id: userProfile.value!.getProfileId(),
              name: userProfile.value!.name,
              phone: userProfile.value!.phone,
            ),
          )
        : "Loading...";
    print(balanceText.value);
  }

  String getGroupBalanceText(Group group) {
    return ExpenseManagerService.getGroupBalanceText(
      Member(
        id: userProfile.value!.getProfileId(),
        name: userProfile.value!.name,
        phone: userProfile.value!.phone,
      ),
      group,
    );
  }
}
