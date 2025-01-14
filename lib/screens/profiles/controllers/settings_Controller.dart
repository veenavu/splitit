// account_settings_controller.dart
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:splitit/screens/profiles/controllers/profile_edit_controller.dart';

import '../../../DatabaseHelper/hive_services.dart';
import '../../../modelClass/models.dart';
import '../../../routes/app_routes.dart';
import '../pages/profileEditPage.dart';


import 'dart:math';

class AccountSettingsController extends GetxController {
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userInitials = ''.obs;
  final Rxn<Profile> currentProfile = Rxn<Profile>();

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final box = await Hive.box(ExpenseManagerService.normalBox);
      final phone = box.get("mobile");

      if (phone == null) {
        throw Exception('Phone number not found');
      }

      final profile = ExpenseManagerService.getProfileByPhone(phone);
      if (profile != null) {
        currentProfile.value = profile;
        userName.value = profile.name;
        userEmail.value = profile.email;

        // Generate initials from name
        final nameParts = profile.name.split(' ');
        if (nameParts.length > 1) {
          userInitials.value = '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
        } else {
          userInitials.value = nameParts[0].substring(0, min(2, nameParts[0].length)).toUpperCase();
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
      Get.snackbar(
        'Error',
        'Failed to load profile: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void clearCache() {
    Get.snackbar(
      'Success',
      'Cache cleared successfully',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void removeOldData() {
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
    Get.to(
            () => const ProfileEditPage(),
        binding: BindingsBuilder(() {
          Get.put(ProfileEditController());
        })
    )?.then((_) {
      // Reload profile data when returning from edit page
      loadProfile();
    });
  }

  void getStatistics(){
    Get.toNamed(Routes.statistics);
  }

}