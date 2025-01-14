import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';

import '../../../modelClass/models.dart';
import '../../../routes/app_routes.dart';
import '../../settlement/memberSettlement_page.dart';
import '../../settlement/settleement_controller/memberSettlement_controller.dart';
import '../controller/friendsPage_controller.dart';

class FriendsPage extends GetView<FriendsController> {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildMembersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() => Row(
            children: [
              Text(
                'Friends (${controller.memberBalances.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.list_alt_outlined),
                onPressed: () => Get.toNamed(Routes.settlementhistory),
                tooltip: 'Settlement History',
              ),
            ],
          )),
    );
  }

  Widget _buildMembersList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (controller.memberBalances.isEmpty) {
        return const Center(
          child: Text(
            'No friends added yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        );
      }

      return RefreshIndicator(
          onRefresh: () async {
            await controller.loadMembers();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: controller.memberBalances.length,
            itemBuilder: (context, index) {
              final memberData = controller.memberBalances[index];
              final Member? member = memberData['member'] as Member?;
              final groupBalances = memberData['groupBalances'] as Map<String, double>?;
              if (member == null) return const SizedBox.shrink();

              // Get balance from the correct key in memberData
              final double balance = (memberData['balance'] as num?)?.toDouble() ?? 0.0;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primaryContainer,
                              Theme.of(context).colorScheme.tertiaryContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.transparent,
                          child: Text(
                            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          controller.getBalanceText(balance),
                          style: TextStyle(
                            color: controller.getBalanceColor(balance),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      trailing: balance.abs() > 0.01
                          ? FilledButton.tonal(
                              onPressed: () {
                                final settlementController = Get.put(MemberSettlementController());
                                Get.to(
                                  () => MemberSettlementPage(
                                    member: member,
                                    totalBalance: balance,
                                    groupBalances: groupBalances,
                                  ),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor:Colors.purple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Settle Up',
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Colors.white
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                    ),
                    // Show group balances if they exist
                    if (memberData['groupBalances'] != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 72, right: 16, bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...(memberData['groupBalances'] as Map<String, double>)
                                .entries
                                .where((entry) => entry.value.abs() > 0.01)
                                .map((entry) {
                              final groupId = entry.key;
                              final groupBalance = entry.value;
                              final group = ExpenseManagerService.getGroupById(int.parse(groupId));

                              return Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.group_outlined,
                                      size: 14,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${group?.groupName ?? 'Group'}: ${controller.getBalanceText(groupBalance)}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: controller.getBalanceColor(groupBalance),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ));
    });
  }
}
