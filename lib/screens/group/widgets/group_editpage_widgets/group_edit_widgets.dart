import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';

class GroupEditWidgets {
  static Widget buildMembersList({
    required List<Member> members,
    required String? currentUserPhone,
    required Function(Member, int) onDeleteMember,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 100),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          final isCurrentUser = member.phone == currentUserPhone;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isCurrentUser ? Colors.purple : Colors.purple.shade100,
                child: Text(
                  member.name[0].toUpperCase(),
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                member.name + (isCurrentUser ? ' (You)' : ''),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                member.phone,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              trailing: isCurrentUser
                  ? null
                  : IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                onPressed: () => onDeleteMember(member, index),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget buildGroupTypeButton({
    required String type,
    required String? selectedType,
    required Function(bool) onSelected,
  }) {
    return RawChip(
      label: Text(
        type,
        style: TextStyle(
          color: selectedType == type ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      selected: selectedType == type,
      onSelected: onSelected,
      selectedColor: Colors.purple,
      backgroundColor: Colors.grey.shade200,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      showCheckmark: false,
    );
  }

  static Widget buildGroupImagePicker({
    required File? imageFile,
    required VoidCallback onTap,
  }) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.purple.shade100,
              backgroundImage: imageFile != null ? FileImage(imageFile) : null,
              child: imageFile == null
                  ? const Icon(Icons.group, size: 50, color: Colors.purple)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.purple,
                child: Icon(
                  imageFile == null ? Icons.add_a_photo : Icons.edit,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildGroupNameField({
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Group Name',
        hintText: 'Enter group name',
        filled: true,
        fillColor: Colors.purple.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.purple.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.purple, width: 2),
        ),
        prefixIcon: const Icon(Icons.group, color: Colors.purple),
      ),
    );
  }

  static void showDeleteMemberDialog({
    required BuildContext context,
    required Member member,
    required int index,
    required Group group,
    required Function() onMemberRemoved,
  }) {
    final double memberBalance = ExpenseManagerService.getGroupBalance(group, member);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Remove ${member.name}',
            style: const TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (memberBalance != 0)
                Text(
                  'Cannot remove ${member.name} as they have pending balance of ₹${memberBalance.abs().toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.red),
                )
              else
                Text(
                  'Are you sure you want to remove ${member.name} from the group?',
                  style: const TextStyle(fontSize: 16),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            if (memberBalance == 0)
              TextButton(
                onPressed: () async {
                  try {
                    group.members.removeAt(index);
                    await ExpenseManagerService.updateGroup(group);
                    Get.back();

                    Get.snackbar(
                      'Success',
                      '${member.name} has been removed from the group',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green.withOpacity(0.1),
                      colorText: Colors.green,
                      duration: const Duration(seconds: 2),
                    );

                    onMemberRemoved();
                  } catch (e) {
                    Get.back();
                    Get.snackbar(
                      'Error',
                      'Failed to remove member: ${e.toString()}',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red.withOpacity(0.1),
                      colorText: Colors.red,
                      duration: const Duration(seconds: 3),
                    );
                  }
                },
                child: const Text(
                  'Remove',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}