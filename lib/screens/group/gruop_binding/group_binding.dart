// Add this binding class
import '../controller/group_controller.dart';
import 'package:get/get.dart';

class AddNewGroupBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AddNewGroupController());
  }
}
