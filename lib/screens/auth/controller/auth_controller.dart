import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/dashboard/dashboard.dart';

class AuthController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final signUpFormKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final signUpPhoneController = TextEditingController();
  RxString? imagePath = ''.obs; // Initialize as nullable

  void login() {
    if (formKey.currentState!.validate()) {
      Profile? userProfile = ExpenseManagerService.getProfileByPhone(phoneController.text);
      if (userProfile != null) {
        final box = Hive.box(ExpenseManagerService.normalBox);
        box.put("mobile", phoneController.text);
        Get.off(const Dashboard());
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Dashboard()));
      } else {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          const SnackBar(content: Text('User not found, please sign up.')),
        );
      }
    }
  }

  Future<void> pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        imagePath!.value = pickedFile.path;
      }
    } catch (e) {
      log("Image picker error: $e");
    }
  }

  Future<void> saveProfileImage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(imagePath!.value).copy('${directory.path}/$fileName');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', savedImage.path);
    } catch (e) {
      log('Error saving profile image: $e');
    }
  }

  Future<void> saveProfileData() async {
    try {
      final profileData = Profile(
        name: nameController.text,
        email: emailController.text,
        phone: signUpPhoneController.text,
        imagePath: imagePath!.value,
      );

      ExpenseManagerService.saveProfile(profileData);
    } catch (e) {
      log('Error saving profile data: $e');
      rethrow; // Re-throw to handle in _submitForm
    }
  }

  Future<void> submitForm() async {
    if (signUpFormKey.currentState!.validate()) {
      try {
        // Save profile image if selected
        await saveProfileImage();

        // Save profile data
        await saveProfileData();

        // Set login status
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        // Show success message
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          const SnackBar(
            content: Text("Profile saved successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to GroupsScreen
        log("Navigating to GroupsScreen...");
        await Future.delayed(const Duration(milliseconds: 500)); // Brief delay for snackbar to be visible

        final box = Hive.box(ExpenseManagerService.normalBox);
        box.put("mobile", signUpPhoneController.text);
        Get.off(() => const Dashboard());
      } catch (e) {
        // Hide loading indicator if showing
        Get.back();

        log("Error in submission: $e");
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text("Error saving profile: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
