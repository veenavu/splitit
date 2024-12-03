import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/expense/controller/expense_controller.dart';
import 'package:splitit/screens/group/group_settings.dart';

import '../../routes/app_routes.dart';
import '../dashboard/controller/dashboard_controller.dart';
import '../settlement/settlement_binding/settlement_binding.dart';
import '../settlement/settlement_page.dart';

class GroupDetails extends StatefulWidget {
  final Group groupItem;

  const GroupDetails({super.key, required this.groupItem});

  @override
  State<GroupDetails> createState() => _GroupDetailsState();
}

class _GroupDetailsState extends State<GroupDetails> {
  List<Expense> expenses = [];
  Expense? myExpense;
  String? phoneNumber;

  double calculateNetAmount(Expense expense, String memberPhone) {
    double netAmount = 0.0;

    if (expense.paidByMember.phone == memberPhone) {
      // When member is the payer
      // Calculate how much they get back (total amount minus their own share)
      double totalLent = 0.0;

      // Calculate total amount lent (sum of all other members' remaining splits)
      for (var split in expense.splits) {
        if (split.member.phone != memberPhone) {
          totalLent += split.amount;
        }
      }

      netAmount = totalLent; // This is what they get back
    } else {
      // When member is not the payer, they only need to pay their split
      for (var split in expense.splits) {
        if (split.member.phone == memberPhone) {
          netAmount = -split.amount; // Negative because they owe this amount
          break;
        }
      }
    }

    return netAmount;
  }

  Future<void> getAllExpenses() async {
    final box = Hive.box(ExpenseManagerService.normalBox);
    phoneNumber = box.get("mobile");
    final groupExpenses = ExpenseManagerService.getExpensesByGroup(widget.groupItem);
    if (mounted) {
      setState(() {
        expenses = groupExpenses;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getAllExpenses();
    // Add listener for settlement updates
    ever(Get.find<DashboardController>().groups, (_) {
      if (mounted) {
        getAllExpenses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenseController = Get.put(ExpenseController());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(), // Navigate back
          tooltip: 'Go Back',
        ),
        title: Text(
          widget.groupItem.groupName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        // Centers the title for a balanced layout
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Group Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupSettings(group: widget.groupItem),
                ),
              );
            },
          ),
        ],
        backgroundColor: Colors.purple,
        elevation: 4,
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
            bottom: Radius.circular(16), // Rounded corners for modern look
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16), // Rounded corners
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1), // Subtle shadow
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Balanced spacing
              children: [
                _buildButton(
                    'Settle Up',
                    Colors.purple,
                    onPressed: () {
                      Get.to(
                            () => SettlementPage(group: widget.groupItem),
                        binding: SettlementBinding(),
                        arguments: {'group': widget.groupItem}, // Pass group as arguments
                      );
                    }
                ),
                _buildButton('Balance', Colors.purple.shade100),
                _buildButton('Total', Colors.purple.shade100),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: expenses.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (BuildContext context, int index) {
                bool isYou = phoneNumber == expenses[index].paidByMember.phone;
                return GestureDetector(
                  onTap: () {
                    expenseController.onExpenseSelected(expenses[index]);
                    _navigateToExpenseDisplay(() {
                      getAllExpenses();
                    });

                  },
                  onLongPress: () async {
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
                                await ExpenseManagerService.deleteExpense(expenses[index]);
                                setState(() {
                                  expenses = ExpenseManagerService.getExpensesByGroup(widget.groupItem);
                                });
                                Get.back();
                              },
                              child: const Text("Yes", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      leading: CircleAvatar(
                        backgroundColor: isYou ? Colors.green.shade100 : Colors.red.shade100,
                        radius: 24,
                        child: Icon(
                          isYou ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isYou ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(
                        expenses[index].description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        '${isYou ? "You" : expenses[index].paidByMember.name} paid ₹${expenses[index].totalAmount.toStringAsFixed(3)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isYou ? 'You lent' : 'You borrowed',
                            style: TextStyle(
                              color: isYou ? Colors.green : Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${calculateNetAmount(expenses[index], phoneNumber!).abs().toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Friends'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
        selectedItemColor: const Color(0xff5f0967),
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  _navigateToExpenseDisplay(VoidCallback callback) {
    Get.toNamed(Routes.displayExpense)!.then((value) {
      callback.call();
    });
  }

  Widget _buildButton(String text, Color color, {VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        // Sets the button background color
        foregroundColor: Colors.white,
        // Sets the text color
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        // Better spacing
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Smooth rounded corners
        ),
        elevation: 3,
        // Adds a slight shadow for depth
        shadowColor: Colors.black.withOpacity(0.2), // Subtle shadow
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
