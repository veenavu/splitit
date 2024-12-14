import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/screens/settlement/settleement_controller/settlemnt_history_controller.dart';
import '../../../modelClass/models.dart';


class SettlementHistoryPage extends GetView<SettlementHistoryController> {
  const SettlementHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settlement History',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (controller.settlements.isEmpty) {
        return const Center(
          child: Text(
            'No settlements yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadSettlements(),
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: controller.settlements.length,
          itemBuilder: (context, index) {
            final settlement = controller.settlements[index];
            return _buildSettlementCard(settlement);
          },
        ),
      );
    });
  }

  Widget _buildSettlementCard(Settlement settlement) {
    final isCurrentUserPayer = controller.isUserInvolved(settlement.payer.phone);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(
          controller.getSettlementDescription(settlement),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '₹${settlement.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: isCurrentUserPayer ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Text(
              controller.getRelativeTimeText(settlement.settledAt),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        children: [
          _buildSettlementDetails(settlement),
        ],
      ),
    );
  }

  Widget _buildSettlementDetails(Settlement settlement) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settlement Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...settlement.expenseSettlements.map((expenseSettlement) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      expenseSettlement.expense.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    '₹${expenseSettlement.settledAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(),
          Row(
            children: [
              const Text(
                'Settled on:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(settlement.settledAt),
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}