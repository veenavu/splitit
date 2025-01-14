import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/dashboard/controller/dashboard_controller.dart';
import 'package:splitit/screens/dashboard/widgets/bottom_action.dart';
import 'package:splitit/screens/dashboard/widgets/expense_list_item.dart';
import 'package:splitit/screens/dashboard/widgets/total_owed.dart';
import 'package:splitit/screens/group/group_details.dart';

import '../../../DatabaseHelper/hive_services.dart';

// In GroupListPage
class GroupListPage extends StatelessWidget {
  const GroupListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() => TotalOwed(
                amount: controller.balanceText.value,
              )),
              IconButton(
                onPressed: () async {
                  final RenderBox button = context.findRenderObject() as RenderBox;
                  final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                  final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);

                  final position = RelativeRect.fromLTRB(
                    buttonPosition.dx + 200,
                    buttonPosition.dy + 50,
                    buttonPosition.dx,
                    buttonPosition.dy + button.size.height + 10,
                  );

                  final result = await showMenu<String>(
                    context: context,
                    position: position,
                    items: const [
                      PopupMenuItem<String>(
                        value: 'all_groups',
                        child: Row(
                          children: [
                            Icon(Icons.group, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('All Groups'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'groups_you_owe',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_upward, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Groups you owe'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'groups_owe_you',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_downward, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Groups that owe you'),
                          ],
                        ),
                      ),
                    ],
                  );

                  if (result != null) {
                    controller.changeFilter(
                        result == 'all_groups' ? 0 : result == 'groups_you_owe' ? 1 : 2
                    );
                  }
                },
                icon: const Icon(Icons.sort),
              )
            ],
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
                itemCount: controller.filteredGroups.length,
                itemBuilder: (context, index) {
                  final groupItem = controller.filteredGroups[index];
                  final currentMember = Member(
                    name: controller.userProfile.value!.name,
                    phone: controller.userProfile.value!.phone,
                    id: controller.userProfile.value!.id,
                  );

                  // Get real-time balance for this group
                  final balance = ExpenseManagerService.calculateGroupBalance(
                      groupItem,
                      currentMember
                  );

                  return GestureDetector(
                    onTap: () {
                      Get.to(() => GroupDetails(groupItem: groupItem))?.then((_) {
                        // Refresh balances after returning from group details
                        controller.loadGroups();
                      });
                    },
                    child: ExpenseListItem(
                      title: groupItem.groupName,
                      subtitle: _getBalanceDisplay(balance),
                      showGroupImage: true,
                      details: [
                        'Last updated: ${_getLastActivityDate(groupItem)}',
                        '${groupItem.members.length} members'
                      ],
                      icon: Icons.group,
                      iconColor: _getBalanceColor(balance.netAmount),
                      groupImage: groupItem.groupImage,
                    ),
                  );
                },
              );
            }),
          ),
          BottomActions(
            onStartGroupComplete: () {
              // Refresh groups and balances when new expense is added
              controller.loadGroups();
            },
          ),
        ],
      ),
    );
  }

  String _getBalanceDisplay(GroupBalance balance) {
    if (balance.netAmount > 0) {
      return 'You get back ₹${balance.netAmount.abs().toStringAsFixed(2)}';
    } else if (balance.netAmount < 0) {
      return 'You owe ₹${balance.netAmount.abs().toStringAsFixed(2)}';
    }
    return 'All settled up';
  }

  Color _getBalanceColor(double amount) {
    if (amount > 0) return Colors.green;
    if (amount < 0) return Colors.red;
    return Colors.grey;
  }

  String _getLastActivityDate(Group group) {
    if (group.expenses.isEmpty) return 'No activity';
    final lastExpense = group.expenses.reduce((a, b) =>
    a.createdAt.isAfter(b.createdAt) ? a : b
    );
    return _formatDate(lastExpense.createdAt);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}