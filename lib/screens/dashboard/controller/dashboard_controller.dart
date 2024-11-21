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

class DashboardController extends GetxController {
  RxList<Group> groups = RxList<Group>.empty(growable: true);
  RxInt selectedIndex = 0.obs;
  Rxn<Profile> userProfile = Rxn<Profile>();
  RxString balanceText = "Loading...".obs;

  List<Widget> pages = <Widget>[
    const GroupListPage(),
    const FriendsPage(),
    const ActivitiesPage(),
    const ProfilePage(),

  ];

  @override
  void onInit() {
    super.onInit();
    loadGroups();
    getProfile();
    getBalanceText();
  }

  Future<void> loadGroups() async {
    final allGroups = ExpenseManagerService.getAllGroups();
    groups.value = allGroups;
    getBalanceText();
  }

  Future<void> getProfile() async {
    final box = Hive.box(ExpenseManagerService.normalBox);
    final phone = box.get("mobile");

    userProfile.value =
        ExpenseManagerService.getProfileByPhone(phone) ?? Profile(name: "User", email: "noob", phone: "2173123");
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
        name: userProfile.value!.name,
        phone: userProfile.value!.phone,
      ),
      group,
    );
  }
}
