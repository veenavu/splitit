import 'package:get/get.dart';
import 'package:splitit/screens/dashboard/controller/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DashboardController());
  }
}
