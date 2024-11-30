import 'package:get/get.dart';
import '../controller/friendsPage_controller.dart';

class FriendsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FriendsController>(
      () => FriendsController(),
      fenix: true, // This ensures the controller persists
    );
  }
}
