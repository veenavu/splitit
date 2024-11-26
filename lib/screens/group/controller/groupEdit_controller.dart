// group_edit_controller.dart
import 'dart:io';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';

import '../../../DatabaseHelper/hive_services.dart';
import '../../../modelClass/models.dart';
import '../../../utils/common_functions.dart';

class GroupEditController extends GetxController {
  final Group group;
  final groupNameController = TextEditingController();
  final RxString imagePath = ''.obs;
  final RxString selectedType = ''.obs;
  final RxList<Member> members = <Member>[].obs;
  final List<String> groupTypes = ['Trip', 'Home', 'Couple', 'Others'];

  GroupEditController(this.group) {
    // Initialize with existing group data
    groupNameController.text = group.groupName;
    imagePath.value = group.groupImage;
    selectedType.value = group.category ?? '';
    members.value = List.from(group.members);
  }

  @override
  void onInit() {
    super.onInit();
    // Additional initialization if needed
  }

  void updateSelectedType(String? type) {
    if (type != null) {
      selectedType.value = type;
    }
  }

  Future<void> addNewMembers(List<Contact>? contacts) async {
    if (contacts == null || contacts.isEmpty) return;

    // Convert contacts to members and check for duplicates
    for (var contact in contacts) {
      final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';

      // Check if member already exists in the group
      bool memberExists = members.any((member) => member.phone == phone);
      if (!memberExists) {
        final newMember = Member(
          name: contact.displayName,
          phone: phone,
        );
        members.add(newMember);
      }
    }
  }

  Future<void> deleteMember(Member member) async {
    // Check if member has any associated expenses in the group
    final expenses = ExpenseManagerService.getExpensesByGroup(group);
    bool hasExpenses = expenses.any((expense) =>
    expense.paidByMember.phone == member.phone ||
        expense.splits.any((split) => split.member.phone == member.phone)
    );

    if (hasExpenses) {
      Get.snackbar(
        'Cannot Delete Member',
        'This member has associated expenses in the group',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    members.remove(member);
  }

  Future<bool> saveGroupChanges() async {
    if (!validateChanges()) return false;

    try {
      // Update group properties
      group.groupName = groupNameController.text;
      group.groupImage = imagePath.value;
      group.category = selectedType.value;
      group.members = members.toList();

      // Save to database
      await ExpenseManagerService.updateGroup(group);

      Get.snackbar(
        'Success',
        'Group updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update group: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return false;
    }
  }

  bool validateChanges() {
    if (groupNameController.text.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Group name cannot be empty',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return false;
    }

    if (members.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Group must have at least one member',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return false;
    }

    return true;
  }

  @override
  void onClose() {
    groupNameController.dispose();
    super.onClose();
  }
}

// group_edit_page.dart
class GroupEditPage extends GetView<GroupEditController> {
  final Group group;

  const GroupEditPage({Key? key, required this.group}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Group'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              if (await controller.saveGroupChanges()) {
                Get.back(result: true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGroupImage(),
              const SizedBox(height: 20),
              _buildGroupNameField(),
              const SizedBox(height: 20),
              _buildGroupTypeSelection(),
              const SizedBox(height: 20),
              _buildMembersList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMembersBottomSheet(context),
        label: const Text('Add Members'),
        icon: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildGroupImage() {
    return Obx(() => GestureDetector(
      onTap: () {
        // Implement image selection logic
      },
      child: Center(
        child: CircleAvatar(
          radius: 50,
          backgroundImage: controller.imagePath.value.isNotEmpty
              ? FileImage(File(controller.imagePath.value))
              : null,
          child: controller.imagePath.value.isEmpty
              ? const Icon(Icons.add_a_photo, size: 40)
              : null,
        ),
      ),
    ));
  }

  Widget _buildGroupNameField() {
    return TextField(
      controller: controller.groupNameController,
      decoration: InputDecoration(
        labelText: 'Group Name',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildGroupTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Group Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: controller.groupTypes.map((type) => Obx(() {
            return ChoiceChip(
              label: Text(type),
              selected: controller.selectedType.value == type,
              onSelected: (selected) {
                controller.updateSelectedType(selected ? type : null);
              },
            );
          })).toList(),
        ),
      ],
    );
  }

  Widget _buildMembersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Members', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Obx(() => ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.members.length,
          itemBuilder: (context, index) {
            final member = controller.members[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text(member.name[0].toUpperCase()),
              ),
              title: Text(member.name),
              subtitle: Text(member.phone),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => controller.deleteMember(member),
              ),
            );
          },
        )),
      ],
    );
  }

  void _showAddMembersBottomSheet(BuildContext context) {
    showMemberAddingBottomSheet(
      context: context,
      onContactsSelected: controller.addNewMembers,
    );
  }
}

// group_edit_binding.dart
class GroupEditBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(GroupEditController(Get.arguments));
  }
}