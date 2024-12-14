import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../modelClass/models.dart';
import '../../controller/expense_controller.dart';

class MembersList extends StatelessWidget {
  final ExpenseController controller;

  const MembersList({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.purple.shade100),
      ),
      child: Obx(() => ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.members.length,
            separatorBuilder: (context, index) => Divider(
              color: Colors.purple.shade50,
              thickness: 1,
            ),
            itemBuilder: (_, index) => MemberListTile(
              member: controller.members[index],
              controller: controller,
            ),
          )),
    );
  }
}

class MemberListTile extends StatelessWidget {
  final Member member;
  final ExpenseController controller;

  const MemberListTile({
    super.key,
    required this.member,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: controller.selectedMembers.contains(member) ? Colors.purple.shade100 : Colors.grey.shade200,
        child: Icon(
          Icons.person_outline,
          color: controller.selectedMembers.contains(member) ? Colors.deepPurple : Colors.grey[600],
        ),
      ),
      title: Text(
        member.name,
        style: TextStyle(
          fontWeight: controller.selectedMembers.contains(member) ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
          color: controller.selectedMembers.contains(member) ? Colors.deepPurple : Colors.black87,
        ),
      ),
      trailing: Obx(() => _buildTrailingWidget()),
      onTap: () => controller.toggleMemberSelection(member),
    );
  }

  Widget _buildTrailingWidget() {
    if (controller.selectedSplitOption.value == 'By Amount') {
      return SizedBox(
        width: 80,
        child: TextField(
          controller: controller.memberAmountControllers[member.phone],
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.purple.shade200),
            ),
            hintText: '0.00',
            hintStyle: TextStyle(color: Colors.purple.shade300),
            filled: true,
            fillColor: Colors.purple.shade50,
          ),
          onChanged: (value) => _handleAmountChange(value),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 24,
      width: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: controller.selectedMembers.contains(member) ? Colors.deepPurple : Colors.transparent,
        border: Border.all(
          color: controller.selectedMembers.contains(member) ? Colors.deepPurple : Colors.grey,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.check,
        size: 16,
        color: controller.selectedMembers.contains(member) ? Colors.white : Colors.transparent,
      ),
    );
  }

  void _handleAmountChange(String value) {
    final amount = double.tryParse(value) ?? 0.0;
    if (amount > 0) {
      if (!controller.selectedMembers.contains(member)) {
        controller.toggleMemberSelection(member);
      }
    } else {
      if (controller.selectedMembers.contains(member)) {
        controller.toggleMemberSelection(member);
      }
    }
    controller.calculateRemaining();
  }
}
