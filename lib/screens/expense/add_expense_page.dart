import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/expense/controller/expense_controller.dart';

class AddExpensePage extends StatelessWidget {
  final Expense? expense;
  final Group? group;

  AddExpensePage({super.key, this.expense, this.group}) {
    final controller = Get.put(ExpenseController());
    controller.initializeExpenseData(expense);
    if (group != null) {
      controller.selectedGroup.value = group;
      controller.members.value = group!.members.toList();
      controller.selectedPayer.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpenseController>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 4,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'New Expense',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => controller.saveExpense(expense),
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            label: const Text('Save'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.shade700,
                Colors.purple.shade400,
              ],
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
        child: Column(
          children: [
            // Group Selection Card
            Card(
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
                              child: Container(
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
                              ),
                            );
                          }).toList(),
                        )),
                  ],
                ),
              ),
            ),

            // Expense Details Card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.purple.shade100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller.amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          color: Colors.purple.shade200,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.currency_rupee,
                          size: 28,
                          color: Colors.purple.shade300,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                    const Divider(
                      height: 32,
                      thickness: 1,
                      color: Colors.purpleAccent,
                    ),
                    TextField(
                      controller: controller.descriptionController,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'What was this expense for?',
                        hintStyle: TextStyle(
                          color: Colors.purple.shade200,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.receipt_outlined,
                          size: 24,
                          color: Colors.purple.shade300,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Split Options Card
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.purple.shade100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Paid by',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Obx(() => DropdownButtonFormField<Member>(
                                    value: controller.selectedPayer.value,
                                    icon: const Icon(
                                      Icons.expand_more_rounded,
                                      size: 20,
                                      color: Colors.deepPurple,
                                    ),
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.purple.shade200),
                                      ),
                                      filled: true,
                                      fillColor: Colors.purple.shade50,
                                    ),
                                    hint: Text(
                                      "Select",
                                      style: TextStyle(color: Colors.purple.shade300),
                                    ),
                                    onChanged: (value) => controller.selectedPayer.value = value,
                                    items: controller.members.map((Member member) {
                                      return DropdownMenuItem<Member>(
                                        value: member,
                                        child: Text(
                                          member.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      );
                                    }).toList(),
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Split',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Obx(() => DropdownButtonFormField<String>(
                                    value: controller.selectedSplitOption.value,
                                    icon: const Icon(
                                      Icons.expand_more_rounded,
                                      size: 20,
                                      color: Colors.deepPurple,
                                    ),
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.purple.shade200),
                                      ),
                                      filled: true,
                                      fillColor: Colors.purple.shade50,
                                    ),
                                    onChanged: controller.onSplitOptionChanged,
                                    items: ['Equally', 'By Amount'].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      );
                                    }).toList(),
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Members List
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.purple.shade100),
              ),
              child: Obx(() => ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.members.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.purple.shade50,
                      thickness: 1,
                    ),
                    itemBuilder: (_, index) {
                      final member = controller.members[index];
                      // final isSelected = controller.selectedMembers.contains(member);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: controller.selectedMembers.contains(member) ? Colors.purple.shade100 : Colors.grey.shade200,
                          child: Icon(
                            Icons.person_outline,
                            color: controller.selectedMembers.contains(member) ? Colors.deepPurple : Colors.grey[600],
                          ),
                        ),
                        title: Text(
                          member.name,
                          style: TextStyle(
                            fontWeight: controller.selectedMembers.contains(member) ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                            color: controller.selectedMembers.contains(member) ? Colors.deepPurple : Colors.black87,
                          ),
                        ),
                        trailing: Obx(
                          () => controller.selectedSplitOption.value == 'By Amount'
                              ? SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: controller.memberAmountControllers[member.phone],
                                    keyboardType: TextInputType.number,
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.purple.shade200),
                                        ),
                                        hintText: '0.00',
                                        hintStyle: TextStyle(color: Colors.purple.shade300),
                                        filled: true,
                                        fillColor: Colors.purple.shade50,
                                      ),
                                      onChanged: (value) {
                                        final amount = double.tryParse(value) ?? 0.0;
                                        if (amount > 0) {
                                          if (!controller.selectedMembers.contains(member)) {
                                            controller.toggleMemberSelection(member);
                                          }
                                        } else {
                                          if (controller.selectedMembers.contains(member)) {
                                            controller.toggleMemberSelection(member);
                                          }
                                        }
                                      }),
                                )
                              : AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 24,
                                  width: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: controller.selectedMembers.contains(member) ? Colors.deepPurple : Colors.transparent,
                                    border: Border.all(
                                      color: controller.selectedMembers.contains(member) ? Colors.deepPurple : Colors.grey,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 16,
                                    color: controller.selectedMembers.contains(member) ? Colors.white : Colors.transparent,
                                  ),
                                ),
                        ),
                        onTap: () => controller.toggleMemberSelection(member),
                      );
                    },
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
