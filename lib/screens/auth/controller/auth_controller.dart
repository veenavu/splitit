import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/dashboard/dashboard.dart';

class AuthController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();

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
}
