import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fl;
import 'package:get/get.dart';

import '../../utils/common_functions.dart';
import 'controller/group_controller.dart';

class AddNewGroupPage extends GetView<AddNewGroupController> {
  const AddNewGroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Group Image Selection
            GestureDetector(
              onTap: controller.pickImage,
              child: Obx(() => Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade200, Colors.purple.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: controller.imagePath.value != null
                        ? ClipOval(
                            child: Image.file(
                              File(controller.imagePath.value!),
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                            ),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 40,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Add Image",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  )),
            ),

            const SizedBox(height: 50),
            // Group Name Input
            TextField(
              controller: controller.groupNameController,
              decoration: InputDecoration(
                hintText: 'Enter Group Name',
                hintStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
                filled: true,
                fillColor: Colors.purple.shade50,
                prefixIcon: const Icon(
                  Icons.group,
                  color: Colors.purple,
                  size: 24,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.purple.shade100),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.purple, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 20),
            // Group Type Selection
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              children: controller.groupTypes
                  .map((type) => Obx(() => RawChip(
                        label: Text(
                          type,
                          style: TextStyle(
                            color: controller.selectedType.value == type ? Colors.white : Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: controller.selectedType.value == type,
                        onSelected: (bool selected) {
                          controller.updateSelectedType(selected ? type : null);
                        },
                        selectedColor: Colors.purple,
                        backgroundColor: Colors.purple.shade50,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.1),
                        pressElevation: 6,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      )))
                  .toList(),
            ),

            const SizedBox(height: 20),
            // Selected Contacts List
            Expanded(
              child: Obx(() => ListView.builder(
                    itemCount: controller.selectedContacts.length,
                    itemBuilder: (context, index) {
                      final contact = controller.selectedContacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: contact.photo != null ? MemoryImage(contact.photo!) : null,
                          child: contact.photo == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(contact.displayName ?? 'No Name'),
                        subtitle: Text(contact.phones.isNotEmpty ? contact.phones.first.number : 'No Phone'),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: Colors.red,
                          onPressed: () => controller.removeContact(index),
                        ),
                      );
                    },
                  )),
            ),
          ],
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
    );
  }
}
