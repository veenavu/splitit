// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:splitit/DatabaseHelper/hive_services.dart';
// import 'package:splitit/modelClass/models.dart';
//
// class GroupsScreen extends StatefulWidget {
//   const GroupsScreen({super.key});
//
//   @override
//   State<GroupsScreen> createState() => _GroupsScreenState();
// }
//
// class _GroupsScreenState extends State<GroupsScreen> {
//   List<Group> groups = [];
//   bool showSettledGroups = false; // Toggle for showing settled and no-expense groups
//
//   @override
//   void initState() {
//     super.initState();
//     ExpenseManagerService.initHive();
//     _loadGroups(); // Load groups when the screen initializes
//   }
//
//   Future<void> _loadGroups() async {
//     final allGroups = ExpenseManagerService.getAllGroups();
//     setState(() {
//       // Separate groups based on their statuses
//       groups = allGroups.where((group) {
//         final status = group.getGroupStatus(null); // Assuming you have a default member
//         return status == "Lent" || status == "Owed";
//       }).toList();
//     });
//   }
//
//   // Filter groups by status and toggle display for settled groups
//   List<Group> getSettledGroups() {
//     return ExpenseManagerService.getAllGroups().where((group) {
//       final status = group.getGroupStatus(null); // Assuming default member
//       return status == "Settled" || status == "No Expense";
//     }).toList();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Groups'),
//         actions: [
//           IconButton(icon: const Icon(Icons.search), onPressed: () {}),
//           IconButton(icon: const Icon(Icons.group), onPressed: () {}),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           children: [
//             TotalOwed(amount: "₹8,654.00"),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: groups.length,
//                 itemBuilder: (context, index) {
//                   final group = groups[index];
//                   final status = group.getGroupStatus(null);
//                   return status == "Settled" || status == "No Expense"
//                       ? const SizedBox.shrink()
//                       : GroupTile(group: group, status: status);
//                 },
//               ),
//             ),
//             if (showSettledGroups) PreviouslySettledGroups(groups: getSettledGroups()),
//             TextButton(
//               onPressed: () {
//                 setState(() {
//                   showSettledGroups = !showSettledGroups;
//                 });
//               },
//               child: Text(
//                 showSettledGroups ? "Hide Settled Groups" : "Show Settled Groups",
//                 style: const TextStyle(color: Colors.blue),
//               ),
//             ),
//             BottomActions(),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: 0,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Groups'),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Friends'),
//           BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Activity'),
//           BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
//         ],
//       ),
//     );
//   }
// }
//
// class TotalOwed extends StatelessWidget {
//   final String amount;
//
//   TotalOwed({required this.amount});
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         children: [
//           const Text("Overall, you are owed ", style: TextStyle(fontSize: 16)),
//           Text(amount, style: const TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }
// }
//
// class GroupTile extends StatelessWidget {
//   final Group group;
//   final String status;
//
//   GroupTile({required this.group, required this.status});
//
//   @override
//   Widget build(BuildContext context) {
//     Color subtitleColor = status == "Lent" ? Colors.green : Colors.red;
//
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 4),
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundImage: FileImage(File(group.groupImage)), // Display the group image
//         ),
//         title: Text(
//           group.groupName,
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         subtitle: Text(
//           status,
//           style: TextStyle(color: subtitleColor, fontWeight: FontWeight.w600),
//         ),
//       ),
//     );
//   }
// }
//
// class PreviouslySettledGroups extends StatelessWidget {
//   final List<Group> groups;
//
//   PreviouslySettledGroups({required this.groups});
//
//   @override
//   Widget build(BuildContext context) {
//     return ExpansionTile(
//       title: const Text("Previously settled groups", style: TextStyle(color: Colors.grey)),
//       children: groups.map((group) => GroupTile(group: group, status: "Settled")).toList(),
//     );
//   }
// }
//
// class BottomActions extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           ElevatedButton.icon(
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => GroupsScreen()),
//               );
//             },
//             icon: const Icon(Icons.group_add),
//             label: const Text("Start a new group"),
//           ),
//           FloatingActionButton(
//             onPressed: () {},
//             child: const Icon(Icons.add),
//             tooltip: "Add Expense",
//           ),
//         ],
//       ),
//     );
//   }
// }
