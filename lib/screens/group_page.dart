import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/add_group.dart';
import 'package:splitit/screens/group_details.dart';
import 'package:splitit/screens/group_search.dart';

import 'add_expense_page.dart';

class GroupPage extends StatefulWidget {
  final VoidCallback? onStartGroupComplete;
  const GroupPage({super.key, this.onStartGroupComplete});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  List<Group> groups = List.empty(growable: true);
  int selectedIndex = 0;
  Profile? userProfile;

  Future<void> _loadGroups() async {
    final allGroups = ExpenseManagerService.getAllGroups();
    setState(() {
      groups = allGroups;
    });
  }

  Future<void> _getProfile() async {
    final box = Hive.box(ExpenseManagerService.normalBox);
    final phone = box.get("mobile");

    setState(() {
      userProfile =
          ExpenseManagerService.getProfileByPhone(phone) ?? Profile(name: "User", email: "noob", phone: "2173123");
    });
  }

  @override
  void initState() {
    _loadGroups();
    _getProfile();
    super.initState();
  }

  void _onStartGroup(VoidCallback? callback, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddNewGroupPage()),
    ).then((value) {
      callback?.call(); // Safely call the callback if not null
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome, ${userProfile?.name ?? 'User'}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        actions: [
          // Search Icon
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            tooltip: 'Search Groups',
            onPressed: () {
              final groups = ExpenseManagerService.getAllGroups();
              showSearch(
                context: context,
                delegate: GroupSearchDelegate(groups, () {
                  _loadGroups();
                }),
              );
            },
          ),
          // Start a New Group Icon
          IconButton(
            icon: const Icon(Icons.group_add, color: Colors.white),
            tooltip: 'Start a New Group',
            onPressed: () {
              _onStartGroup(() {
                widget.onStartGroupComplete?.call(); // Safe null-aware callback
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
            TotalOwed(
              amount: userProfile != null
                  ? ExpenseManagerService.getBalanceText(
                Member(name: userProfile!.name, phone: userProfile!.phone),
              )
                  : "Loading...",
            ),
            Expanded(
              child: ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final groupItem = groups[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupDetails(
                            groupItem: groupItem,
                          ),
                        ),
                      ).then((value) {
                        _loadGroups();
                      });
                    },
                    child: ExpenseListItem(
                      title: groupItem.groupName,
                      subtitle: ExpenseManagerService.getGroupBalanceText(
                        Member(name: userProfile!.name, phone: userProfile!.phone),
                        groupItem,
                      ),
                      showGroupImage: index % 2 == 0 ? false : true,
                      details: const [],
                      icon: Icons.article, // This will be ignored if groupImage is provided
                      iconColor: Colors.red[700]!,
                      groupImage: groupItem.groupImage, // Pass the group image path
                    ),

                  );
                },
              ),
            ),
            BottomActions(
              onStartGroupComplete: () {
                _loadGroups();
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.group, color: Colors.black),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.black),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt, color: Colors.black),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle, color: Colors.black),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

class TotalOwed extends StatelessWidget {
  final String amount;

  const TotalOwed({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Text("Overall, ", style: TextStyle(fontSize: 16)),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              color: amount.contains("owe")
                  ? Colors.red
                  : amount.contains("settle")
                  ? Colors.grey
                  : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddExpensePage()),
            );
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
class ExpenseListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String>? details;
  final IconData? icon;
  final Color iconColor;
  final bool showImage;
  final bool showGroupImage;
  final String? groupImage; // Add the groupImage property

  const ExpenseListItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.details,
    this.icon,
    required this.iconColor,
    this.showImage = false,
    this.showGroupImage = false,
    this.groupImage, // Accept groupImage
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: groupImage != null ? Colors.transparent : iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: groupImage != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(groupImage!), // Display the groupImage
              fit: BoxFit.cover,
            ),
          )
              : Icon(
            icon ?? Icons.article, // Fallback to icon if groupImage is null
            color: iconColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: TextStyle(
                color: subtitle.contains('owe')
                    ? Colors.orange
                    : subtitle.contains('lent')
                    ? Colors.green
                    : Colors.grey,
                fontSize: 14,
              ),
            ),
            if (details != null) ...[
              const SizedBox(height: 4),
              ...details!.map(
                    (detail) => Text(
                  detail,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

