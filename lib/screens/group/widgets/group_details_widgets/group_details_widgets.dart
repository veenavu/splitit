// group_details_widgets.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/settlement/settlement_binding/settlement_binding.dart';
import 'package:splitit/screens/settlement/settlement_page.dart';

class GroupDetailsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Group groupItem;
  final VoidCallback onSettingsTap;

  const GroupDetailsAppBar({
    Key? key,
    required this.groupItem,
    required this.onSettingsTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Get.back(),
        tooltip: 'Go Back',
      ),
      title: Text(
        groupItem.groupName,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          tooltip: 'Group Settings',
          onPressed: onSettingsTap,
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
          bottom: Radius.circular(16),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ActionButtonsContainer extends StatelessWidget {
  final Group groupItem;

  const ActionButtonsContainer({
    Key? key,
    required this.groupItem,
  }) : super(key: key);

  Widget _buildButton(String text, Color color, {VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.2),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildButton(
            'Settle Up',
            Colors.purple,
            onPressed: () {
              Get.to(
                    () => SettlementPage(group: groupItem),
                binding: SettlementBinding(),
                arguments: {'group': groupItem},
              );
            },
          ),
          _buildButton('Balance', Colors.purple.shade100),
          _buildButton('Total', Colors.purple.shade100),
        ],
      ),
    );
  }
}

class ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final String phoneNumber;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(Expense, String) calculateNetAmount;

  const ExpenseListItem({
    Key? key,
    required this.expense,
    required this.phoneNumber,
    required this.onTap,
    required this.onLongPress,
    required this.calculateNetAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isYou = phoneNumber == expense.paidByMember.phone;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
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
            expense.description,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            '${isYou ? "You" : expense.paidByMember.name} paid ₹${expense.totalAmount.toStringAsFixed(3)}',
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
                '₹${calculateNetAmount(expense, phoneNumber).abs().toStringAsFixed(2)}',
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
  }
}

class GroupBottomNavigationBar extends StatelessWidget {
  const GroupBottomNavigationBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Groups'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Friends'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Activity'),
        BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
      ],
      selectedItemColor: const Color(0xff5f0967),
      unselectedItemColor: Colors.grey,
    );
  }
}