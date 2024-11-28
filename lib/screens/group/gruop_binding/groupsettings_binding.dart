

import 'package:get/get.dart';
import 'package:splitit/screens/group/controller/groupsetting_controller.dart';

class GroupSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GroupSettingsController>(() =>
        GroupSettingsController(Get.arguments['group'])
    );
  }
}