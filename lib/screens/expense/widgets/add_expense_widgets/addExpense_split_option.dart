import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../modelClass/models.dart';
import '../../controller/expense_controller.dart';

class ExpenseSplitOptions extends StatelessWidget {
  final ExpenseController controller;

  const ExpenseSplitOptions({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.purple.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: PayerDropdown(controller: controller),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SplitOptionDropdown(controller: controller),
            ),
          ],
        ),
      ),
    );
  }
}
// Inside expense_split_options.dart

class PayerDropdown extends StatelessWidget {
  final ExpenseController controller;

  const PayerDropdown({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class SplitOptionDropdown extends StatelessWidget {
  final ExpenseController controller;

  const SplitOptionDropdown({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}
