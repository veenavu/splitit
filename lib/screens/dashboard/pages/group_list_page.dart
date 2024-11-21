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
          Obx(() => TotalOwed(
            amount: controller.balanceText.value,
          )),
          Expanded(
            child: Obx(() => ListView.builder(
              itemCount: controller.groups.length,
              itemBuilder: (context, index) {
                final groupItem = controller.groups[index];
                return GestureDetector(
                  onTap: () {
                    // final b = ExpenseManagerService.getMemberGroupExpense(Member(
                    //   name: controller.userProfile.value!.name,
                    //   phone: controller.userProfile.value!.phone,
                    // ), groupItem);
                    // print(b.netBalance);
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
