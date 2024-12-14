// add_expense_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/expense/controller/expense_controller.dart';

import 'package:splitit/screens/expense/widgets/add_expense_widgets/Addexpense_details_card.dart';
import 'package:splitit/screens/expense/widgets/add_expense_widgets/addExpense_group_selection.dart';
import 'package:splitit/screens/expense/widgets/add_expense_widgets/addExpense_member_list.dart';
import 'package:splitit/screens/expense/widgets/add_expense_widgets/addExpense_split_option.dart';

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
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(controller),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ExpenseGroupSelection(controller: controller),
            ExpenseDetailsCard(controller: controller),
            ExpenseSplitOptions(controller: controller),
            MembersList(controller: controller),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, controller),
    );
  }

  PreferredSizeWidget _buildAppBar(ExpenseController controller) {
    return AppBar(
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
    );
  }

  Widget _buildBottomBar(BuildContext context, ExpenseController controller) {
    return Obx(() {
      if (controller.selectedSplitOption.value != 'By Amount') {
        return const SizedBox.shrink(); // Return empty widget instead of null
      }

      double totalEntered = controller.memberAmountControllers.values.map((c) => double.tryParse(c.text) ?? 0.0).fold(0.0, (sum, amount) => sum + amount);

      double totalAmount = double.tryParse(controller.amountController.text) ?? 0.0;
      double remaining = totalAmount - totalEntered;

      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      "Total: ₹${totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                Text(
                  "Remaining: ₹${controller.remaining.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: remaining < 0 ? Colors.red : Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
