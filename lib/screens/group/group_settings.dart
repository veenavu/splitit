import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/routes/app_routes.dart';
import 'package:splitit/screens/dashboard/controller/dashboard_controller.dart';
import 'package:splitit/screens/group/group_editpage.dart';
import 'package:splitit/screens/group/widgets/group_settings_widgets/group_settings_widgets.dart';


class GroupSettings extends StatefulWidget {
  Group group;

  GroupSettings({super.key, required this.group});

  @override
  State<GroupSettings> createState() => _GroupSettingsState();
}

class _GroupSettingsState extends State<GroupSettings> {
  String? currentUserPhone;

  @override
  void initState() {
    super.initState();
    getCurrentUserPhone();
  }

  void getCurrentUserPhone() {
    final box = Hive.box(ExpenseManagerService.normalBox);
    currentUserPhone = box.get("mobile");
  }

  String buildMemberBalanceSubtitle(String currentUserPhone, Member member) {
    double balance = 0.0;
    List<Expense> expenses = ExpenseManagerService.getExpensesByGroup(widget.group);

    for (var expense in expenses) {
      if (expense.paidByMember.phone == member.phone) {
        final lentAmount = expense.splits
            .where((split) => split.member.phone != member.phone)
            .fold(0.0, (sum, split) => sum + split.amount);
        balance += lentAmount;
      }

      final memberSplit = expense.splits
          .firstWhereOrNull((split) => split.member.phone == member.phone);

      if (memberSplit != null && expense.paidByMember.phone != member.phone) {
        balance -= memberSplit.amount;
      }
    }

    if (member.phone == currentUserPhone) {
      if (balance > 0) {
        return 'You get back ₹${balance.toStringAsFixed(2)}';
      } else if (balance < 0) {
        return 'You owe ₹${(-balance).toStringAsFixed(2)}';
      }
      return 'All settled up';
    } else {
      if (balance > 0) {
        return 'Gets back ₹${balance.toStringAsFixed(2)}';
      } else if (balance < 0) {
        return 'Owes ₹${(-balance).toStringAsFixed(2)}';
      }
      return 'All settled up';
    }
  }

  void _handleDeleteGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Group"),
        content: const Text(
          "Are you sure you want to delete this group? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              ExpenseManagerService.deleteGroup(widget.group);
              await Future.delayed(const Duration(milliseconds: 100));
              Future.microtask(() {
                Get.offNamedUntil(
                  Routes.dashboard,
                      (route) => route.settings.name == Routes.dashboard,
                );
                Get.find<DashboardController>().loadGroups();
              });
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleEditGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupEditPage(groups: widget.group),
      ),
    );

    if (result == true) {
      final updatedGroup = ExpenseManagerService.getGroupById(widget.group.id!);
      if (updatedGroup != null) {
        setState(() {
          widget.group = updatedGroup;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GroupAppBar(
        onBack: () => Get.back(),
        onEdit: _handleEditGroup,
        onDelete: _handleDeleteGroup,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            GroupImageWidget(groupImage: widget.group.groupImage),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  GroupNameDisplay(groupName: widget.group.groupName),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: MemberCountDisplay(memberCount: widget.group.members.length),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: ListView.builder(
                itemCount: widget.group.members.length,
                itemBuilder: (context, index) {
                  final member = widget.group.members[index];
                  return MemberListItem(
                    member: member,
                    balanceSubtitle: buildMemberBalanceSubtitle(
                      currentUserPhone ?? '',
                      member,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}