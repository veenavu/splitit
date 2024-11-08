import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/add_group.dart';
import 'package:splitit/screens/group_details.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

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

  _getProfile() async {
    final box = Hive.box(ExpenseManagerService.normalBox);
    final phone = box.get("mobile");

    setState(() {
      userProfile = ExpenseManagerService.getProfileByPhone(phone) ?? Profile(name: "User", email: "noob", phone: "2173123");
    });
  }

  @override
  void initState() {
    _loadGroups();
    _getProfile();
    super.initState();
  }


  @override
  void didChangeDependencies() {

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${userProfile?.name}'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.group), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const TotalOwed(amount: "₹8,654.00"),
            Expanded(
              child: ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final groupItem = groups[index];
                  // final status = groupItem.getGroupStatus(null);
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=> GroupDetails(groupItem: groupItem,))).then((value) => _loadGroups());
                    },
                    child: ExpenseListItem(
                      title: groupItem.groupName,
                      subtitle: 'you are owed ₹17.38',
                      showGroupImage: index % 2 == 0 ? false : true,
                      details: const [
                        'Abdul R. owes you ₹12.00',
                        'Jishna R. owes you ₹5.38',
                      ],
                      icon: Icons.article,
                      iconColor: Colors.red[700]!,
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
        // This affects both icon and label color when selected
        unselectedItemColor: Colors.black,
        // This affects both icon and label color when not selected
        selectedLabelStyle: const TextStyle(
          color: Color(0xff5f0967), // Purple color for selected label
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          color: Colors.black, // Black color for unselected label
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.group,
              color: Colors.black,
            ),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                color: Colors.black,
              ),
              label: 'Friends'),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.receipt,
                color: Colors.black,
              ),
              label: 'Activity'),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.account_circle,
                color: Colors.black,
              ),
              label: 'Account'),
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
          const Text("Overall, you are owed ", style: TextStyle(fontSize: 16)),
          Text(amount, style: const TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class GroupTile extends StatelessWidget {
  final Group group;
  final String status;

  const GroupTile({super.key, required this.group, required this.status});

  @override
  Widget build(BuildContext context) {
    Color subtitleColor = status == "Lent" ? Colors.green : Colors.red;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: FileImage(File(group.groupImage)), // Display the group image
        ),
        title: Text(
          group.groupName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          status,
          style: TextStyle(color: subtitleColor, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class BottomActions extends StatelessWidget {
  final VoidCallback onStartGroupComplete;

  const BottomActions({super.key, required this.onStartGroupComplete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              _onStartGroup(() {
                onStartGroupComplete.call();
              }, context);
            },
            icon: const Icon(Icons.group_add,color: Color(0xff5f0967),),
            label: const Text("Start a new group", style: TextStyle(color: Color(0xff5f0967)),),
          ),
          FloatingActionButton.extended(
            onPressed: () {},
            tooltip: "Add Expense",
            icon: const Icon(Icons.add),
            label: const Text("Add Expense"),
          ),
        ],
      ),
    );
  }

  _onStartGroup(VoidCallback callback, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddNewGroupPage()),
    ).then((value) => callback.call());
  }
}

class ExpenseListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String>? details;
  final IconData icon;
  final Color iconColor;
  final bool showImage;
  final bool showGroupImage;

  const ExpenseListItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.details,
    required this.icon,
    required this.iconColor,
    this.showImage = false,
    this.showGroupImage = false,
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
            color: showImage || showGroupImage ? Colors.transparent : iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: showImage || showGroupImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: Colors.grey[800],
                    child: Icon(
                      showGroupImage ? Icons.group : Icons.apartment,
                      color: Colors.white,
                    ),
                  ),
                )
              : Icon(
                  icon,
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
                color: subtitle.contains('owe') ? Colors.orange : Colors.grey,
                fontSize: 14,
              ),
            ),
            if (details != null) ...[
              const SizedBox(height: 4),
              ...details!.map((detail) => Text(
                    detail,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  )),
            ],
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
