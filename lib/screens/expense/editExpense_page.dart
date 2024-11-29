import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/expense/controller/expense_controller.dart';
import 'dart:io';



class ExpenseEditPage extends GetView<ExpenseController> {
  final Expense expense;

  ExpenseEditPage({super.key, required this.expense}) {
    final controller = Get.put(ExpenseController());
    controller.initializeExpenseData(expense);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.purple,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Edit Expense',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => controller.saveExpense(expense),
            child: const Text(
              'Update',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Obx(() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount and Description Card
            _buildAmountSection(),
            const SizedBox(height: 16),

            // Group Selection
            if (controller.groups.isNotEmpty) ...[
              _buildGroupSection(),
              const SizedBox(height: 16),
            ],

            // Split Options
            _buildSplitOptionsSection(),
            const SizedBox(height: 16),

            // Members List
            _buildMembersSection(),
          ],
        ),
      )),
      bottomNavigationBar: Obx(() => _buildBottomBar()),
    );
  }

  Widget _buildAmountSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller.amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                prefixStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.purple.shade200),
                ),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  controller.calculateRemaining();
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.purple.shade200),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Group',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Group>(
              value: controller.selectedGroup.value,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.purple.shade200),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: controller.groups.map((group) {
                return DropdownMenuItem(
                  value: group,
                  child: Row(
                    children: [
                      if (group.groupImage.isNotEmpty) ...[
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: FileImage(File(group.groupImage)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(group.groupName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: controller.onGroupChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitOptionsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Member>(
                        value: controller.selectedPayer.value,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.purple.shade200),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: controller.members.map((member) {
                          return DropdownMenuItem(
                            value: member,
                            child: Text(member.name),
                          );
                        }).toList(),
                        onChanged: (value) => controller.selectedPayer.value = value,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Split Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: controller.selectedSplitOption.value,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.purple.shade200),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: ['Equally', 'By Amount'].map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            controller.onSplitOptionChanged(value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.members.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final member = controller.members[index];
          final isSelected = controller.selectedMembers.contains(member);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected ? Colors.purple.shade100 : Colors.grey.shade200,
              child: Text(
                member.name[0].toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.purple : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              member.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: controller.selectedSplitOption.value == 'By Amount'
                ? SizedBox(
              width: 120,
              child: TextField(
                controller: controller.memberAmountControllers[member.phone],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.purple.shade200),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    final amount = double.tryParse(value) ?? 0.0;
                    if (amount > 0 && !isSelected) {
                      controller.toggleMemberSelection(member);
                    } else if (amount <= 0 && isSelected) {
                      controller.toggleMemberSelection(member);
                    }
                    controller.calculateRemaining();
                  }
                },
              ),
            )
                : Checkbox(
              value: isSelected,
              onChanged: (_) => controller.toggleMemberSelection(member),
              activeColor: Colors.purple,
            ),
            onTap: () {
              if (controller.selectedSplitOption.value != 'By Amount') {
                controller.toggleMemberSelection(member);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    if (controller.selectedSplitOption.value != 'By Amount') {
      return const SizedBox.shrink();
    }

    final totalAmount = double.tryParse(controller.amountController.text) ?? 0.0;
    final totalEntered = controller.memberAmountControllers.values
        .map((c) => double.tryParse(c.text) ?? 0.0)
        .fold(0.0, (sum, amount) => sum + amount);
    final remaining = totalAmount - totalEntered;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total: ₹${totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Remaining: ₹${remaining.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: remaining == 0
                    ? Colors.green
                    : remaining < 0
                    ? Colors.red
                    : Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}