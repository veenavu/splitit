// add_group.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/screens/group/widgets/add_group_widgets/add_group_imagePicker.dart';
import 'package:splitit/screens/group/widgets/add_group_widgets/add_group_name_input.dart';
import 'package:splitit/screens/group/widgets/add_group_widgets/add_group_selected_contact_list.dart';
import 'package:splitit/screens/group/widgets/add_group_widgets/add_group_type_selector.dart';
import '../../utils/common_functions.dart';
import 'controller/group_controller.dart';


class AddNewGroupPage extends GetView<AddNewGroupController> {
  const AddNewGroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<AddNewGroupController>( // Wrap with GetX
      init: AddNewGroupController(), // Initialize the controller
      builder: (controller) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
            tooltip: 'Go Back',
            iconSize: 28,
            color: Colors.white,
          ),
          title: const Text(
            "Add New Group",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.check, size: 28),
              onPressed: controller.saveGroup,
              tooltip: 'Save Group',
              color: Colors.white,
            ),
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.deepPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 30),
                // Group Image Selection
                GroupImagePicker(
                  imagePath: controller.imagePath.value,
                  onTap: controller.pickImage,
                ),

                const SizedBox(height: 50),
                // Group Name Input
                GroupNameInput(controller: controller.groupNameController),

                const SizedBox(height: 20),
                // Group Type Selection
                GroupTypeSelector(
                  groupTypes: controller.groupTypes,
                  selectedType: controller.selectedType.value,
                  onTypeSelected: controller.updateSelectedType,
                ),

                const SizedBox(height: 20),
                // Selected Contacts List
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4, // Fixed height
                  child: SelectedContactsList(
                    contacts: controller.selectedContacts,
                    onRemove: controller.removeContact,
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            showMemberAddingBottomSheet(
              context: context,
              onContactsSelected: controller.addSelectedContacts,
            );
          },
          label: const Row(
            children: [
              Icon(Icons.person_add, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "Add Members",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: Colors.purple,
        ),
      ),
    );
  }
}