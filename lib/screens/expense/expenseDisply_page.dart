import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/screens/expense/controller/expense_controller.dart';

import '../../DatabaseHelper/hive_services.dart';
import '../../modelClass/models.dart';
import '../../routes/app_routes.dart';
import '../dashboard/controller/dashboard_controller.dart';

class ExpenseDisplayPage extends StatefulWidget {
  // final Expense expense;

  const ExpenseDisplayPage({
    Key? key,
    // required this.expense,
  }) : super(key: key);

  @override
  State<ExpenseDisplayPage> createState() => _ExpenseDisplayPageState();
}

class _ExpenseDisplayPageState extends State<ExpenseDisplayPage> {
  late Expense expense;
  final ExpenseController expenseController = Get.find<ExpenseController>();



  @override
  void initState() {
    // TODO: implement initState
    // final expenseController =;
    //
    // expense = expenseController.selectedExpense!.value;
    super.initState();
    expense = expenseController.selectedExpense;
    // Listen for changes to the expense
    ever(expenseController.groups, (_) {
      if (mounted) {
        setState(() {
          expense = expenseController.selectedExpense;
        });
      }
    });

  }
  void refreshExpense() {
    setState(() {
      expense = expenseController.selectedExpense;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  getInitData() {}

  @override
  Widget build(BuildContext context) {
    //Expense expense = Get.find<ExpenseController>().selectedExpense;

    // final expense = expenseController.selectedExpense.value;
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
              // Get.toNamed(Routes.ediitExpense, arguments: {'expense': expense, 'group': expense.group});
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
            // Amount Card
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '₹${expense.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      expense.description,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Paid by ${expense.paidByMember.name}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Split Details Card
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Split Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            expense.divisionMethod == DivisionMethod.equal ? 'Split Equally' : 'Custom Split',
                            style: TextStyle(
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: expense.splits.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.purple.shade50,
                        thickness: 1,
                      ),
                      itemBuilder: (context, index) {
                        final split = expense.splits[index];
                        final isPayer = split.member.phone == expense.paidByMember.phone;

                        // Calculate the net amount for this split
                        double netAmount;
                        if (isPayer) {
                          // For the payer: they get back everything except their own share
                          netAmount = expense.totalAmount - split.amount;
                        } else {
                          // For others: they owe their share
                          netAmount = -split.amount;
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isPayer ? Colors.green.shade100 : Colors.purple.shade100,
                            child: Icon(
                              isPayer ? Icons.arrow_upward : Icons.arrow_downward,
                              color: isPayer ? Colors.green : Colors.purple,
                            ),
                          ),
                          title: Text(
                            split.member.name + (isPayer ? ' (Paid)' : ''),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isPayer ? 'gets back' : 'owes',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '₹${netAmount.abs().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isPayer ? Colors.green : Colors.purple,
                                ),
                              ),
                              if (expense.divisionMethod == DivisionMethod.percentage && split.percentage != null)
                                Text(
                                  '${split.percentage!.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Additional Info Card
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
                    Text(
                      'Additional Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Group',
                      expense.group?.groupName ?? 'Personal Expense',
                      Icons.group,
                    ),

                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Date',
                      _formatDate(expense.createdAt),
                      Icons.calendar_today,
                    ),
                    if (expense.note != null && expense.note!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Note',
                        expense.note!,
                        Icons.note,
                      ),
                    ],
                  ],
                ),
              ),
            ),
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
                      // Navigate back to dashboard
                      Get.until((route) => Get.currentRoute == Routes.dashboard);
                    },
                    child: const Text("Yes", style: TextStyle(color: Colors.red)),
                  ),
                ],
              );
            },
          );
        },
        icon: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
        label: const Text(
          'Delete Expense',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
      ),
    );
  }

  _navigateToEditPage(VoidCallback callback) {
    Get.toNamed(
      Routes.ediitExpense,
    )?.then((value) {
      callback.call();
    });
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.purple.shade400,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  
}
