import 'package:get/get.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';

class GroupSettingsController extends GetxController {
  final Rx<Group> group;
  final Rx<Profile?> currentProfile = Rx<Profile?>(null);
  GroupSettingsController(Group initialGroup) : group = Rx<Group>(initialGroup);

  void updateGroupData() {
    // Renamed from refreshGroup to updateGroupData
    final updatedGroup = ExpenseManagerService.getGroupById(group.value.id!);
    if (updatedGroup != null) {
      group.value = updatedGroup;
    }
  }

  // Add method to update current profile
  void updateCurrentProfile(Profile? profile) {
    currentProfile.value = profile;
  }

  Future<void> deleteGroup() async {
    await ExpenseManagerService.deleteGroup(group.value);
  }
}
