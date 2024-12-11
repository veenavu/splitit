// account_settings_controller.dart
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../DatabaseHelper/hive_services.dart';
import '../../../routes/app_routes.dart';

class AccountSettingsController extends GetxController {
  final RxString userName = 'Veena V U'.obs;
  final RxString userEmail = 'veena@gmail.com'.obs;
  final RxString userInitials = 'VV'.obs;

  void clearCache() {
    // Implement cache clearing logic
    Get.snackbar(
      'Success',
      'Cache cleared successfully',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void removeOldData() {
    // Implement data removal logic
    Get.snackbar(
      'Success',
      'Old data removed successfully',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void logout() {
    final box = Hive.box(ExpenseManagerService.normalBox);

    box.put("isLoggedIn", false);

    Get.offAllNamed(Routes.login);

  }

  void editProfile() {
    // Implement profile editing logic
    Get.toNamed('/edit-profile');
  }

  void getStatistics(){
    Get.toNamed(Routes.statistics);
  }

}