import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../modelClass/models.dart';
import '../../controller/expense_controller.dart';

class SplitOptionsCard extends StatelessWidget {
  final ExpenseController controller;

  const SplitOptionsCard({
    Key? key,
    required this.controller,
  }) : super(key: key);


  Widget _buildPayerDropdown() {
    return Obx(() {
      final currentMembers = controller.members;
      final currentPayer = controller.selectedPayer.value;

      // Debug prints to help diagnose the issue
      print('Current members: ${currentMembers.map((m) => '${m.name}:${m.phone}')}');
      print('Selected payer: ${currentPayer?.name}:${currentPayer?.phone}');

      // If no members, show a placeholder
      if (currentMembers.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.purple.shade200),
            borderRadius: BorderRadius.circular(12),
            color: Colors.purple.shade50,
          ),
          child: Text(
            "No members available",
            style: TextStyle(color: Colors.purple.shade300),
          ),
        );
      }

      // Create unique items using phone number as key
      final items = currentMembers.map((Member member) {
        return DropdownMenuItem<String>(
          value: member.phone, // Use phone as unique identifier
          child: Text(
            member.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList();

      return DropdownButtonFormField<String>(
        value: currentPayer?.phone, // Use phone number as value
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
          "Select payer",
          style: TextStyle(color: Colors.purple.shade300),
        ),
        onChanged: (String? phoneNumber) {
          if (phoneNumber != null) {
            final selectedMember = currentMembers.firstWhere(
                  (m) => m.phone == phoneNumber,
              orElse: () => currentMembers.first,
            );
            controller.selectedPayer.value = selectedMember;
          }
        },
        items: items,
      );
    });
  }


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
                      // In edit_expense_split_option_card.dart

                      _buildPayerDropdown(),
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
    );
  }
}
