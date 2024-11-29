import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../DatabaseHelper/hive_services.dart';
import '../../modelClass/models.dart';


class ExpenseDisplayPage extends StatelessWidget {
  final Expense expense;

  const ExpenseDisplayPage({
    Key? key,
    required this.expense,
  }) : super(key: key);

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
              Get.toNamed('/add-expense', arguments: {'expense': expense});
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
                            expense.divisionMethod == DivisionMethod.equal
                                ? 'Split Equally'
                                : 'Custom Split',
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
                            backgroundColor: isPayer
                                ? Colors.green.shade100
                                : Colors.purple.shade100,
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
                    // const SizedBox(height: 12),
                    // _buildInfoRow(
                    //   'Category',
                    //   expense.category ?? 'Uncategorized',
                    //   Icons.category,
                    // ),
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
        onPressed: () => _showDeleteConfirmation(context),
        icon: const Icon(Icons.delete,color: Colors.white,),
        label: const Text('Delete Expense',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.purple,
      ),
    );
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

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Expense',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this expense? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await ExpenseManagerService.deleteExpense(expense);
                  Get.back();  // Close dialog
                  Get.back();  // Return to previous screen
                  Get.snackbar(
                    'Success',
                    'Expense deleted successfully',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green.withOpacity(0.1),
                    colorText: Colors.green,
                  );
                } catch (e) {
                  Get.snackbar(
                    'Error',
                    'Failed to delete expense: ${e.toString()}',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red.withOpacity(0.1),
                    colorText: Colors.red,
                  );
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}