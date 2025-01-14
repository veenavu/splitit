import 'dart:io';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:splitit/screens/profiles/controllers/settings_Controller.dart';

import '../../../DatabaseHelper/hive_services.dart';
import '../../../modelClass/models.dart';


import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';

import '../../dashboard/controller/dashboard_controller.dart';
import '../../expense/controller/expense_controller.dart';

class ProfileEditController extends GetxController {
  final profile = Rxn<Profile>();
  final imageFile = Rxn<File>();
  final isLoading = false.obs;
  final isProfileLoaded = false.obs;  // New flag to track profile loading state

  final nameController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final box = Hive.box(ExpenseManagerService.normalBox);
      final phone = box.get("mobile");

      if (phone == null) {
        throw Exception('Phone number not found');
      }

      final userProfile = ExpenseManagerService.getProfileByPhone(phone);
      if (userProfile == null) {
        throw Exception('Profile not found');
      }

      profile.value = userProfile;
      nameController.text = userProfile.name;
      emailController.text = userProfile.email;

      if (userProfile.imagePath != null && userProfile.imagePath!.isNotEmpty) {
        final file = File(userProfile.imagePath!);
        if (await file.exists()) {
          imageFile.value = file;
        }
      }

      isProfileLoaded.value = true;
    } catch (e) {
      print('Error loading profile: $e');
      Get.snackbar(
        'Error',
        'Failed to load profile: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      Get.back();
    }
  }

  Future<void> pickImage() async {
    try {
      final pickedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Compress image
      );

      if (pickedImage != null) {
        final file = File(pickedImage.path);
        if (await file.exists()) {
          imageFile.value = file;
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }


  Future<void> saveProfile() async {
    if (!isProfileLoaded.value || profile.value == null) {
      Get.snackbar(
        'Error',
        'Profile not loaded properly',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Validate input
      if (nameController.text.trim().isEmpty) {
        throw Exception('Name cannot be empty');
      }

      if (!GetUtils.isEmail(emailController.text.trim())) {
        throw Exception('Please enter a valid email');
      }

      // Check if image file exists before using its path
      String? imagePath = profile.value?.imagePath;
      if (imageFile.value != null && await imageFile.value!.exists()) {
        imagePath = imageFile.value!.path;
      }

      final updatedProfile = Profile(
        id: profile.value!.id,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: profile.value!.phone,
        imagePath: imagePath,
      );

      await ExpenseManagerService.updateProfile(updatedProfile);

      // Update all groups where this user is a member
      await _updateMemberDetailsInGroups(updatedProfile);

      // Update DashboardController
      if (Get.isRegistered<DashboardController>()) {
        final dashboardController = Get.find<DashboardController>();
        dashboardController.userProfile.value = updatedProfile;
        dashboardController.update(['dashboard_profile']); // Force UI update
        dashboardController.loadGroups();
      }

      // Update AccountSettingsController
      if (Get.isRegistered<AccountSettingsController>()) {
        final settingsController = Get.find<AccountSettingsController>();
        settingsController.currentProfile.value = updatedProfile;
        await settingsController.loadProfile();
      }
      Get.back();

      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );


    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateMemberDetailsInGroups(Profile updatedProfile) async {
    final allGroups = ExpenseManagerService.getAllGroups();
    final allExpenses = ExpenseManagerService.getAllExpenses();

    // First update member details in groups
    for (var group in allGroups) {
      bool groupUpdated = false;

      for (var i = 0; i < group.members.length; i++) {
        if (group.members[i].phone == updatedProfile.phone) {
          group.members[i] = Member(
            id: group.members[i].id,
            name: updatedProfile.name,
            phone: updatedProfile.phone,
            imagePath: updatedProfile.imagePath,
            totalAmountOwedByMe: group.members[i].totalAmountOwedByMe,
            balancesByGroup: group.members[i].balancesByGroup,
            transactionHistory: group.members[i].transactionHistory,
          );
          groupUpdated = true;
        }
      }

      if (groupUpdated) {
        await ExpenseManagerService.updateGroup(group);
      }
    }

    // Then update member details in all expenses
    for (var expense in allExpenses) {
      bool expenseUpdated = false;

      // Update payer if it matches
      if (expense.paidByMember.phone == updatedProfile.phone) {
        expense.paidByMember = Member(
          id: expense.paidByMember.id,
          name: updatedProfile.name,
          phone: updatedProfile.phone,
          imagePath: updatedProfile.imagePath,
        );
        expenseUpdated = true;
      }

      // Update splits if they match
      for (var split in expense.splits) {
        if (split.member.phone == updatedProfile.phone) {
          split.member = Member(
            id: split.member.id,
            name: updatedProfile.name,
            phone: updatedProfile.phone,
            imagePath: updatedProfile.imagePath,
          );
          expenseUpdated = true;
        }
      }

      if (expenseUpdated) {
        await expense.save();
      }
    }

    // Update ExpenseController if it exists
    if (Get.isRegistered<ExpenseController>()) {
      final expenseController = Get.find<ExpenseController>();
      // If there's a selected expense, refresh it
      if (expenseController.selectedExpense != null) {
        final updatedExpense = allExpenses.firstWhere(
              (e) => e.id == expenseController.selectedExpense.id,
          orElse: () => expenseController.selectedExpense,
        );
        expenseController.onExpenseSelected(updatedExpense);
      }
    }

    // Refresh the dashboard
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().loadGroups();
    }
  }


  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    super.onClose();
  }
}