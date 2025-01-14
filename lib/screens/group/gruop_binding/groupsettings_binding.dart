import 'package:get/get.dart';
import 'package:splitit/screens/group/controller/groupsetting_controller.dart';
import '../../../modelClass/models.dart';

class GroupSettingsBinding extends Bindings {
  final Group group;

  GroupSettingsBinding(this.group);

  @override
  void dependencies() {
    Get.put(GroupSettingsController(group));
  }
}