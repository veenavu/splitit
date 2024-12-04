import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/screens/expense/widgets/edit_expense_widgets/edit_expense_amount_validation_bar.dart';
import 'package:splitit/screens/expense/widgets/edit_expense_widgets/edit_expense_details_card.dart';
import 'package:splitit/screens/expense/widgets/edit_expense_widgets/edit_expense_member_list_card.dart';
import 'package:splitit/screens/expense/widgets/edit_expense_widgets/edit_expense_split_option_card.dart';

import 'controller/expense_controller.dart';


class EditExpensePage extends StatelessWidget {
  EditExpensePage({super.key}) {
    final controller = Get.put(ExpenseController());
    var expense = controller.selectedExpense;
    controller.initializeExpenseData(controller.selectedExpense);
    controller.descriptionController.text = expense.description;
    controller.amountController.text = expense.totalAmount.toString();
    controller.selectedGroup.value = expense.group;
    if (expense.group != null) {
      controller.members.value = expense.group!.members.toList();
    }
    controller.selectedPayer.value = expense.paidByMember;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpenseController>();
    var expense = controller.selectedExpense;
    var group = controller.selectedExpense.group!;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(context, group, controller, expense),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ExpenseDetailsCard(controller: controller),
            SplitOptionsCard(controller: controller),
            MembersListCard(controller: controller),
          ],
        ),
      ),
      bottomNavigationBar: AmountValidationBar(controller: controller),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, group, ExpenseController controller, expense) {
    return AppBar(
      centerTitle: true,
      elevation: 4,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      title: Text(
        group.groupName,
        style: const TextStyle(
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
    );
  }
}