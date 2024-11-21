import 'package:get/get.dart';
import 'package:splitit/screens/auth/controller/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthController());
  }
}