import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/screens/dashboard/controller/dashboard_controller.dart';
import 'package:splitit/screens/dashboard/widgets/bottom_action.dart';
import 'package:splitit/screens/dashboard/widgets/expense_list_item.dart';
import 'package:splitit/screens/dashboard/widgets/total_owed.dart';
import 'package:splitit/screens/group/group_details.dart';

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
                  // Get the RenderBox of the IconButton
                  final RenderBox button = context.findRenderObject() as RenderBox;
                  final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

                  final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);

                  // Position the menu to the right of the button
                  final position = RelativeRect.fromLTRB(
                    buttonPosition.dx + 200, // Move menu to the right by adjusting left position
                    buttonPosition.dy + 50, // Position below the button
                    buttonPosition.dx,
                    buttonPosition.dy + button.size.height + 10,
                  );

                  // Show the popup menu
                  final result = await showMenu<String>(
                    context: context,
                    position: position,
                    items: [
                      const PopupMenuItem<String>(
                        value: 'all_groups',
                        child: Row(
                          children: [
                            Icon(Icons.group, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('All Groups'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'groups_you_owe',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_upward, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Groups you owe'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'groups_owe_you',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_downward, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Groups that owe you'),
                          ],
                        ),
                      ),
                    ],
                    elevation: 8.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );

                  // Handle the selected menu item
                  if (result != null) {
                    switch (result) {
                      case 'all_groups':
                      // Handle All Groups selection
                        controller.changeFilter(0);
                        break;
                      case 'groups_you_owe':
                      // Handle Groups you owe selection
                        controller.changeFilter(1);
                        break;
                      case 'groups_owe_you':
                        controller.changeFilter(2);
                        // Handle Groups that owe you selection
                        break;
                    }
                  }
                },
                icon: const Icon(Icons.sort),
              )
            ],
          ),
          Expanded(
            child: Obx(() => ListView.builder(
              itemCount: controller.filteredGroups.length,
              itemBuilder: (context, index) {
                final groupItem = controller.filteredGroups[index];
                return GestureDetector(
                  onTap: () {
                    Get.to(()=> GroupDetails(groupItem: groupItem))?.then((value) {
                      controller.loadGroups();
                    });
                  },
                  child: ExpenseListItem(
                    title: groupItem.groupName,
                    subtitle: controller.getGroupBalanceText(groupItem),
                    showGroupImage: index % 2 == 0 ? false : true,
                    details: const [],
                    icon: Icons.article,
                    iconColor: Colors.red[700]!,
                    groupImage: groupItem.groupImage,
                  ),
                );
              },
            )),
          ),
          BottomActions(
            onStartGroupComplete: (){
              controller.loadGroups();
            },
          ),
        ],
      ),
    );
  }
}
