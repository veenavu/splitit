import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/routes/app_routes.dart';
import 'package:splitit/screens/expense/add_expense_page.dart';

class BottomActions extends StatelessWidget {
  final VoidCallback onStartGroupComplete;

  const BottomActions({super.key, required this.onStartGroupComplete});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FloatingActionButton.extended(
          onPressed: () {

            Get.to(() =>  AddExpensePage())?.then(
                    (onValue) => onStartGroupComplete.call());
          },
          tooltip: "Add Expense",
          icon: const Icon(
            Icons.add,
            size: 24,
            color: Colors.white,
          ),
          label: const Text(
            "Add Expense",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          backgroundColor: const Color(0xffab47bc),
        ),
      ),
    );
  }
}
