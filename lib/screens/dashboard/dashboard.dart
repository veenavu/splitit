import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/dashboard/controller/dashboard_controller.dart';
import 'package:splitit/screens/dashboard/widgets/bottom_action.dart';
import 'package:splitit/screens/dashboard/widgets/expense_list_item.dart';
import 'package:splitit/screens/dashboard/widgets/total_owed.dart';
import 'package:splitit/screens/group/group_details.dart';
import 'package:splitit/screens/group/group_search.dart';

class Dashboard extends StatelessWidget {
  final VoidCallback? onStartGroupComplete;

  const Dashboard({super.key, this.onStartGroupComplete});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              'Welcome, ${controller.userProfile.value?.name ?? 'User'}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            tooltip: 'Search Groups',
            onPressed: () {
              showSearch(
                context: context,
                delegate: GroupSearchDelegate(
                  controller.groups,
                  controller.loadGroups,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.group_add, color: Colors.white),
            tooltip: 'Start a New Group',
            onPressed: () {
              controller.onStartGroup(() {
                controller.loadGroups();
              }, context);
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
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: Padding(
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
                          final b = ExpenseManagerService.getMemberGroupExpense(Member(
                            name: controller.userProfile.value!.name,
                            phone: controller.userProfile.value!.phone,
                          ), groupItem);
                          print(b.netBalance);
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
      ),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
            currentIndex: controller.selectedIndex.value,
            onTap: (index) {
              controller.selectedIndex.value = index;
            },
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.black,
            selectedLabelStyle: const TextStyle(
              color: Color(0xff5f0967),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.group, color: Colors.black),
                label: 'Groups',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person, color: Colors.black),
                label: 'Friends',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.receipt, color: Colors.black),
                label: 'Activity',
              ),
              BottomNavigationBarItem(
                icon: controller.userProfile.value?.imagePath != null &&
                        controller.userProfile.value!.imagePath!.isNotEmpty
                    ? CircleAvatar(
                        radius: 12,
                        backgroundImage: FileImage(File(controller.userProfile.value!.imagePath!)),
                        backgroundColor: Colors.transparent,
                      )
                    : const Icon(Icons.account_circle, color: Colors.black),
                label: controller.userProfile.value?.name ?? "Account",
              ),
            ],
          )),
    );
  }
}
