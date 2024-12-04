// expense_group_selection.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/expense/controller/expense_controller.dart';
import 'dart:io';

class ExpenseGroupSelection extends StatelessWidget {
  final ExpenseController controller;

  const ExpenseGroupSelection({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.purple.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Group',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => DropdownButtonFormField<Group>(
                  value: controller.selectedGroup.value,
                  icon: const Icon(
                    Icons.expand_more_rounded,
                    size: 20,
                    color: Colors.deepPurple,
                  ),
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.purple.shade200),
                    ),
                    filled: true,
                    fillColor: Colors.purple.shade50,
                  ),
                  hint: Text(
                    "Choose a group",
                    style: TextStyle(color: Colors.purple.shade300),
                  ),
                  onChanged: controller.onGroupChanged,
                  items: controller.groups.map((Group group) {
                    return DropdownMenuItem<Group>(
                      value: group,
                      child: GroupDropdownItem(group: group),
                    );
                  }).toList(),
                )),
          ],
        ),
      ),
    );
  }
}

class GroupDropdownItem extends StatelessWidget {
  final Group group;

  const GroupDropdownItem({
    Key? key,
    required this.group,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: FileImage(File(group.groupImage)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                group.groupName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                group.category ?? 'No category',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
