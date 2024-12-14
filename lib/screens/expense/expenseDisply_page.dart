import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/screens/expense/controller/expense_controller.dart';
import 'package:splitit/screens/expense/widgets/expense_display_widgets/display_expense_additional_display_card.dart';
import 'package:splitit/screens/expense/widgets/expense_display_widgets/display_expense_amount_card.dart';
import 'package:splitit/screens/expense/widgets/expense_display_widgets/display_expense_split_details_card.dart';
import '../../DatabaseHelper/hive_services.dart';
import '../../modelClass/models.dart';
import '../../routes/app_routes.dart';
import '../dashboard/controller/dashboard_controller.dart';

class ExpenseDisplayPage extends StatefulWidget {
  const ExpenseDisplayPage({super.key});

  @override
  State<ExpenseDisplayPage> createState() => _ExpenseDisplayPageState();
}

class _ExpenseDisplayPageState extends State<ExpenseDisplayPage> {
  late Expense expense;
  final ExpenseController expenseController = Get.find<ExpenseController>();

  @override
  void initState() {
    super.initState();
    expense = expenseController.selectedExpense;
    ever(expenseController.groups, (_) {
      if (mounted) {
        setState(() {
          expense = expenseController.selectedExpense;
        });
      }
    });
  }

  void _navigateToEditPage(VoidCallback callback) {
    Get.toNamed(Routes.ediitExpense)?.then((value) {
      callback.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
          tooltip: 'Back',
        ),
        title: const Text(
          'Expense Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.purple,
        elevation: 4,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              _navigateToEditPage(() {
                setState(() {
                  expense = Get.find<ExpenseController>().selectedExpense;
                });
              });
            },
            tooltip: 'Edit Expense',
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.deepPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ExpenseAmountCard(expense: expense),
            ExpenseSplitDetailsCard(expense: expense),
            ExpenseAdditionalInfoCard(expense: expense),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Delete Expense"),
                content: const Text("Do you want to delete this expense?"),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ExpenseManagerService.deleteExpense(expense);
                      Get.back();
                      Get.find<DashboardController>().loadGroups();
                      Get.find<DashboardController>().getBalanceText();
                      Get.until((route) => Get.currentRoute == Routes.dashboard);
                    },
                    child: const Text("Yes", style: TextStyle(color: Colors.red)),
                  ),
                ],
              );
            },
          );
        },
        icon: const Icon(Icons.delete, color: Colors.white),
        label: const Text('Delete Expense', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
      ),
    );
  }
}