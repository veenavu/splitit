import 'package:flutter/material.dart';

import '../../controller/expense_controller.dart';

class ExpenseDetailsCard extends StatelessWidget {
  final ExpenseController controller;

  const ExpenseDetailsCard({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
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
            AmountTextField(controller: controller),
            const Divider(
              height: 32,
              thickness: 1,
              color: Colors.purpleAccent,
            ),
            DescriptionTextField(controller: controller),
          ],
        ),
      ),
    );
  }
}

class AmountTextField extends StatelessWidget {
  final ExpenseController controller;

  const AmountTextField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
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
      onChanged: (val) {
        controller.remaining.value = double.tryParse(val) ?? 0.0;
      },
    );
  }
}

class DescriptionTextField extends StatelessWidget {
  final ExpenseController controller;

  const DescriptionTextField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
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
    );
  }
}
