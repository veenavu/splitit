import 'package:get/get.dart';

import '../controller/activityPage_controller.dart';

class ActivityPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ActivityController>(
          () => ActivityController(),
      fenix: true,
    );
  }
}