import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/screens/settlement/settleement_controller/memberSettlement_controller.dart';

import '../../modelClass/models.dart';



class MemberSettlementPage extends GetView<MemberSettlementController> {
  final Member member;
  final double totalBalance;

  const MemberSettlementPage({
    Key? key,
    required this.member,
    required this.totalBalance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUserOwing = totalBalance < 0;

    // Initialize controller with member data
    controller.loadGroupBalances(member, isUserOwing);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settle with ${member.name}', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          _buildSettlementHeader(isUserOwing),
          _buildCustomAmountSection(),
          _buildGroupsList(),
          _buildSettleButton(isUserOwing),
        ],
      ),
    );
  }

  Widget _buildSettlementHeader(bool isUserOwing) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.purple.shade50,
      child: Column(
        children: [
          Text(
            isUserOwing
                ? 'You owe ${member.name}'
                : '${member.name} owes you',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${totalBalance.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isUserOwing ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAmountSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Obx(() => Checkbox(
                value: controller.isCustomAmount.value,
                onChanged: (value) {
                  controller.isCustomAmount.value = value ?? false;
                  if (!value!) {
                    controller.customAmount.value = totalBalance.abs();
                  }
                },
              )),
              const Text('Enter custom amount'),
            ],
          ),
          Obx(() => controller.isCustomAmount.value
              ? TextField(
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '₹',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              controller.customAmount.value = double.tryParse(value) ?? 0;
            },
          )
              : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList() {
    return Expanded(
      child: Obx(() => ListView.builder(
        itemCount: controller.groupBalances.length,
        itemBuilder: (context, index) {
          final groupData = controller.groupBalances[index];
          final group = groupData['group'] as Group;
          final balance = groupData['balance'] as double;
          final isSettled = groupData['isSettled'] as bool;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(group.groupName),
              subtitle: Text(
                isSettled
                    ? 'Settled'
                    : '₹${balance.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  color: isSettled
                      ? Colors.grey
                      : balance < 0 ? Colors.red : Colors.green,
                ),
              ),
              trailing: isSettled
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
          );
        },
      )),
    );
  }

  Widget _buildSettleButton(bool isUserOwing) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Obx(() => ElevatedButton(
        onPressed: controller.isProcessing.value
            ? null
            : () {
              final amount = controller.isCustomAmount.value
                  ? controller.customAmount.value
                  : totalBalance.abs();

              final selectedGroups = controller.groupBalances
                  .where((g) => !g['isSettled'])
                  .map((g) => g['group'] as Group)
                  .toList();

              controller.recordSettlement(
                payer: isUserOwing
                    ? controller.currentUser.value!.toMember()
                    : member,
                receiver: isUserOwing
                    ? member
                    : controller.currentUser.value!.toMember(),
                amount: amount,
                selectedGroups: selectedGroups,
              );
              Get.back();

        },
    style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        minimumSize: const Size(double.infinity, 50),
      ),
        child: controller.isProcessing.value
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Record Settlement', style: TextStyle(color: Colors.white)),
      ))


    );
  }
}

extension ProfileToMember on Profile {
  Member toMember() {
    return Member(
      name: name,
      phone: phone,
      imagePath: imagePath,
    );
  }
}