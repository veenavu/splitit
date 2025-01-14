import 'package:get/get.dart';

import '../controller/groupEdit_controller.dart';

class GroupEditBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(GroupEditController(Get.arguments));
  }
}
