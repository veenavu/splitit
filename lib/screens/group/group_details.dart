import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/expense/controller/expense_controller.dart';
import 'package:splitit/screens/group/group_settings.dart';
import 'package:splitit/screens/group/widgets/group_details_widgets/group_details_widgets.dart';
import '../../routes/app_routes.dart';
import '../dashboard/controller/dashboard_controller.dart';

class GroupDetails extends StatefulWidget {
  final Group groupItem;

  const GroupDetails({super.key, required this.groupItem});

  @override
  State<GroupDetails> createState() => _GroupDetailsState();
}

class _GroupDetailsState extends State<GroupDetails> {
  List<Expense> expenses = [];
  String? phoneNumber;

  double calculateNetAmount(Expense expense, String memberPhone) {
    double netAmount = 0.0;

    if (expense.paidByMember.phone == memberPhone) {
      double totalLent = 0.0;
      for (var split in expense.splits) {
        if (split.member.phone != memberPhone) {
          totalLent += split.amount;
        }
      }
      netAmount = totalLent;
    } else {
      for (var split in expense.splits) {
        if (split.member.phone == memberPhone) {
          netAmount = -split.amount;
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

  void _navigateToExpenseDisplay(VoidCallback callback) {
    Get.toNamed(Routes.displayExpense)!.then((value) {
      callback.call();
    });
  }

  void _handleExpenseDelete(Expense expense) async {
    await ExpenseManagerService.deleteExpense(expense);
    setState(() {
      expenses = ExpenseManagerService.getExpensesByGroup(widget.groupItem);
    });
    Get.back();
  }

  void _showDeleteDialog(Expense expense) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Expense"),
          content: const Text("Do you want to delete this expense?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => _handleExpenseDelete(expense),
              child: const Text("Yes", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    getAllExpenses();
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
      appBar: GroupDetailsAppBar(
        groupItem: widget.groupItem,
        onSettingsTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupSettings(group: widget.groupItem),
            ),
          );
        },
      ),
      body: Column(
        children: [
          ActionButtonsContainer(groupItem: widget.groupItem),
          Expanded(
            child: ListView.builder(
              itemCount: expenses.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                return ExpenseListItem(
                  expense: expenses[index],
                  phoneNumber: phoneNumber!,
                  onTap: () {
                    expenseController.onExpenseSelected(expenses[index]);
                    _navigateToExpenseDisplay(() {
                      getAllExpenses();
                    });
                  },
                  onLongPress: () => _showDeleteDialog(expenses[index]),
                  calculateNetAmount: calculateNetAmount,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const GroupBottomNavigationBar(),
    );
  }
}