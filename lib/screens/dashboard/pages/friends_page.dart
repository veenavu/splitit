import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../modelClass/models.dart';
import '../../settlement/memberSettlement_page.dart';
import '../../settlement/settleement_controller/memberSettlement_controller.dart';
import '../../settlement/settlement_binding/settlement_binding.dart';
import '../../settlement/settlement_page.dart';
import '../controller/friendsPage_controller.dart';

class FriendsPage extends GetView<FriendsController> {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure controller is initialized
    final controller = Get.find<FriendsController>();

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
                icon: const Icon(Icons.search),
                onPressed: () {
                  // TODO: Implement search functionality
                },
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
          controller.loadMembers();
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: controller.memberBalances.length,
          itemBuilder: (context, index) {
            final memberData = controller.memberBalances[index];
            final Member member = memberData['member'];
            final double balance = memberData['balance'];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.shade100,
                  radius: 24,
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
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
                trailing: balance != 0
                    ? ElevatedButton(
                  onPressed: () {
                    Get.put(MemberSettlementController());
                    Get.to(
                          () => MemberSettlementPage(
                        member: member,
                        totalBalance: balance,
                      ),
                    );
                  },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Settle Up'),
                      )
                    : const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
              ),
            );
          },
        ),
      );
    });
  }
}
