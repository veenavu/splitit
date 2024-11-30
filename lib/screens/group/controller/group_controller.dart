import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fl;
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';

class AddNewGroupController extends GetxController {
  // Observable variables
  final groupNameController = TextEditingController();
  final selectedType = Rxn<String>();
  final imagePath = Rxn<String>();
  final selectedContacts = <Contact>[].obs;
  final isLoading = false.obs;

  // Constants
  final List<String> groupTypes = ['Trip', 'Home', 'Couple', 'Others'];

  @override
  void onInit() {
    super.onInit();
    _initializeHiveAndCleanup();
  }

  Future<void> _initializeHiveAndCleanup() async {
    try {
      // Clear all existing data and reinitialize
      // await ExpenseManagerService.clearAllBoxesAndData();
    } catch (e) {
      print('Error initializing Hive: $e');
      Get.snackbar(
        'Error',
        'Failed to initialize database. Please restart the app.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  // Image Picker
  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      String? savedPath = await _saveImagePath(File(pickedFile.path));
      imagePath.value = savedPath;
    }
  }

  Future<String?> _saveImagePath(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png';
      final savedImage = await imageFile.copy(filePath);
      return savedImage.path;
    } catch (e) {
      print("Error saving image: $e");
      return null;
    }
  }

  // Contact Management
  void addSelectedContacts(List<fl.Contact>? contacts) {
    if (contacts != null) {
      for (var contact in contacts) {
        if (!selectedContacts.contains(contact)) {
          selectedContacts.add(contact);
        }
      }
    }
  }

  void removeContact(int index) {
    Get.dialog(
      AlertDialog(
        title: const Text("Delete Member"),
        content: const Text("Do you want to delete this member?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              selectedContacts.removeAt(index);
              Get.back();
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  void updateSelectedType(String? type) {
    selectedType.value = type;
  }

  Future<List<Member>> _convertContactsToMembers() async {
    return Future.wait(selectedContacts.map((contact) async {
      String? imagePath;
      if (contact.photo != null) {
        imagePath = await _saveContactImage(File.fromRawPath(contact.photo!), contact.displayName ?? 'contact_image');
      }
      return Member(
        name: contact.displayName,
        phone: contact.phones.isNotEmpty ? contact.phones.first.number : 'No Phone',
        imagePath: imagePath,
      );
    }).toList());
  }

  Future<String?> _saveContactImage(File imageFile, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName.png';
    try {
      final savedImage = await imageFile.copy(filePath);
      return savedImage.path;
    } catch (e) {
      print("Error saving contact image: $e");
      return null;
    }
  }

  bool validateInputs() {
    return groupNameController.text.isNotEmpty && imagePath.value != null && selectedType.value != null && selectedContacts.isNotEmpty;
  }

  // Group Saving
  Future<void> saveGroup() async {
    if (!validateInputs()) {
      Get.snackbar(
        'Error',
        'Please fill in all fields and add members',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Convert contacts to members
      List<Member> members = await _convertContactsToMembers();

      // Add current user to group members
      final box = Hive.box(ExpenseManagerService.normalBox);
      final phone = box.get("mobile");
      Profile? userProfile = ExpenseManagerService.getProfileByPhone(phone);

      if (userProfile != null) {
        members.add(Member(
          name: userProfile.name,
          phone: userProfile.phone,
          imagePath: userProfile.imagePath,
          // Add any new required fields here
        ));
      }

      // Create and save group
      Group group = Group(
        groupName: groupNameController.text,
        groupImage: imagePath.value!,
        category: selectedType.value,
        members: members,
        // Add any new required fields here
      );

      await ExpenseManagerService.saveTheGroup(group);

      Get.back();
      Get.snackbar(
        'Success',
        'Group created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
    } catch (e) {
      print('Error saving group: $e');
      Get.snackbar(
        'Error',
        'Failed to create group. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    groupNameController.dispose();
    super.onClose();
  }
}
