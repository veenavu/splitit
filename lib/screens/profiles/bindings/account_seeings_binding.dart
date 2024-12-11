import 'package:get/get.dart';

import '../controllers/settings_Controller.dart';


class AccountSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AccountSettingsController>(() => AccountSettingsController());
  }
}