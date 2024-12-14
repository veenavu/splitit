// settlement_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/screens/settlement/settleement_controller/settlement_controller.dart';
import '../../modelClass/models.dart';


class SettlementPage extends GetView<SettlementController> {
  final Group group;

  const SettlementPage({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
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
        title: Text(
          'Settle up - ${group.groupName}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              controller.calculateSettlements(group);
            },
          ),
        ],
      ),
      body: Obx(() {
        final settlements = controller.settlements;

        if (settlements.isEmpty) {
          return const Center(
            child: Text(
              'All settled up! 🎉',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          );
        }

        return ListView.builder(
          itemCount: settlements.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final settlement = settlements[index];
            return _buildSettlementCard(settlement);
          },
        );
      }),
    );
  }

  Widget _buildSettlementCard(SettlementTransaction settlement) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showSettlementDialog(settlement),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Payer Info
              Row(
                children: [
                  _buildAvatar(settlement.payer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settlement.payer.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          'needs to pay',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Amount
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '₹${settlement.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.purple,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Receiver Info
              Row(
                children: [
                  _buildAvatar(settlement.receiver),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settlement.receiver.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          'will receive',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),
              TextButton.icon(
                onPressed: () => _showSettlementDialog(settlement),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Record Settlement'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Member member) {
    return CircleAvatar(
      radius: 24,
      backgroundImage:
      member.imagePath != null ? AssetImage(member.imagePath!) : null,
      child: member.imagePath == null
          ? Text(
        member.name[0].toUpperCase(),
        style: const TextStyle(fontSize: 20),
      )
          : null,
    );
  }

  void _showSettlementDialog(SettlementTransaction settlement) {
    Get.defaultDialog(
      title: 'Record Settlement',
      content: Text(
        'Are you sure ${settlement.payer.name} has paid ₹${settlement.amount.toStringAsFixed(2)} to ${settlement.receiver.name}?',
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            await controller.recordSettlement(
              payer: settlement.payer,
              receiver: settlement.receiver,
              amount: settlement.amount,
              group: group,
            );
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}