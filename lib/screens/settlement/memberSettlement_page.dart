import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/screens/dashboard/controller/dashboard_controller.dart';
import 'package:splitit/screens/dashboard/controller/friendsPage_controller.dart';
import 'package:splitit/screens/settlement/settleement_controller/memberSettlement_controller.dart';

import '../../modelClass/models.dart';


class MemberSettlementPage extends GetView<MemberSettlementController> {
  final Member member;
  final double totalBalance;
  final Map<String, double>? groupBalances;

  const MemberSettlementPage({
    super.key,
    required this.member,
    required this.totalBalance,
    required this.groupBalances,
  });

  @override
  Widget build(BuildContext context) {
    controller.initializeWithMember(member, totalBalance);
    final isUserOwing = controller.isUserOwing(totalBalance);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settle with ${member.name}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.deepPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSettlementHeader(),
          _buildCustomAmountSection(),
          _buildGroupsList(),
          _buildSettleButton(isUserOwing),
        ],
      ),
    );
  }

  Widget _buildSettlementHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.purple.shade50,
      child: Column(
        children: [
          Text(
            controller.getBalanceText(totalBalance),
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
              color: totalBalance > 0 ? Colors.red : Colors.green,
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
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            controller: TextEditingController(
              text: totalBalance.abs().toString(),
            ),
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

          return Visibility(
            visible: group.members.any((mem)=> mem.phone == member.phone),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(group.groupName),
                subtitle: Text(
                  isSettled ? 'Settled' : controller.getBalanceText(balance, member: member),
                  style: TextStyle(
                    color: isSettled ? Colors.grey :
                    balance < 0 ? Colors.red : Colors.green,
                  ),
                ),
                trailing: isSettled
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : Text(
                  '₹${balance.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: balance < 0 ? Colors.red : Colors.green,
                  ),
                ),
              ),
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
            : () async{
          // Determine settlement amount - either custom amount if specified, or total balance
          final amount = controller.isCustomAmount.value
              ? controller.customAmount.value
              : totalBalance.abs();

                    for (var grp in controller.groupBalances) {
                      var amt = grp['balance'] as double;
                      var singleGrp = grp['group'] as Group;

                      if(singleGrp.members.any((mem)=> mem.phone == member.phone)){
                        await ExpenseManagerService.createExpense(
                            totalAmount: controller.isCustomAmount.value
                                ? controller.customAmount.value
                                : amt.abs(),
                            divisionMethod: DivisionMethod.equal,
                            paidByMember: amt > 0
                                ? member
                                : Member(
                              // If user owes money, they are the payer
                              name: controller.currentUser.value!.name,
                              phone: controller.currentUser.value!.phone,
                              imagePath: controller.currentUser.value!.imagePath,
                            ),
                            involvedMembers: [
                              amt > 0
                                  ? Member(
                                // If user owes money, they are the payer
                                name: controller.currentUser.value!.name,
                                phone: controller.currentUser.value!.phone,
                                imagePath: controller.currentUser.value!.imagePath,
                              )
                                  : member
                            ],
                            description: "Settlement with ${member.name}",
                            group: singleGrp,
                            customAmounts: null);
                      }
                    }

          Get.find<DashboardController>().getBalanceText();

          if (Get.isRegistered<FriendsController>()) {
            await Get.find<FriendsController>().handleSuccessfulSettlement();
          }

          // Update dashboard
          Get.put(FriendsController()).loadMembers();
          Get.find<DashboardController>().loadGroups();

          Get.back();
          Get.snackbar(
            'Success',
            'Settlement recorded successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.green,
          );
          //           // Filter and map group balances to get list of unsettled groups
          // final selectedGroups = controller.groupBalances
          //     .where((g) => !g['isSettled'])  // Filter out settled groups
          //     .map((g) => g['group'] as Group)  // Extract Group object from map
          //     .toList();
          //
          // // Record the settlement transaction with payer and receiver details
          // controller.recordSettlement(
          //   // Determine payer based on who owes money
          //   payer: isUserOwing
          //       ? Member(  // If user owes money, they are the payer
          //     name: controller.currentUser.value!.name,
          //     phone: controller.currentUser.value!.phone,
          //     imagePath: controller.currentUser.value!.imagePath,
          //   )
          //       : member,  // Otherwise, the other member is the payer
          //
          //   // Determine receiver based on who is owed money
          //   receiver: isUserOwing
          //       ? member  // If user owes money, other member is receiver
          //       : Member(  // Otherwise, user is the receiver
          //     name: controller.currentUser.value!.name,
          //     phone: controller.currentUser.value!.phone,
          //     imagePath: controller.currentUser.value!.imagePath,
          //   ),
          //
          //   amount: amount,  // Settlement amount determined above
          //   selectedGroups: selectedGroups,  // List of unsettled groups determined above
          // );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          minimumSize: const Size(double.infinity, 50),
        ),
        child: controller.isProcessing.value
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
          'Record Settlement',
          style: TextStyle(color: Colors.white),
        ),
      )),
    );
  }
}