// DashboardController
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/routes/app_routes.dart';

class DashboardController extends GetxController {
  RxList<Group> groups = RxList<Group>.empty(growable: true);
  RxInt selectedIndex = 0.obs;
  Rxn<Profile> userProfile = Rxn<Profile>();

  @override
  void onInit() {
    super.onInit();
    loadGroups();
    getProfile();
  }

  Future<void> loadGroups() async {
    final allGroups = ExpenseManagerService.getAllGroups();
    groups.value = allGroups;
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

  String getBalanceText() {
    return userProfile.value != null
        ? ExpenseManagerService.getBalanceText(
            Member(
              name: userProfile.value!.name,
              phone: userProfile.value!.phone,
            ),
          )
        : "Loading...";
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
