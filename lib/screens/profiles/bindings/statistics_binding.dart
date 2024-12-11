
import 'package:get/get.dart';
import '../controllers/staticstics_controller.dart';

class StatisticsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StatisticsController>(() => StatisticsController());
  }
}