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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.settlements.isEmpty) {
        return const Center(
          child: Text(
            'No settlements yet',
            style: TextStyle(fontSize: 16, color: Colors.grey),
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
            return _buildSettlementCard(context, settlement);
          },
        ),
      );
    });
  }

  Widget _buildSettlementCard(BuildContext context, Settlement settlement) {
    final isCurrentUserPayer = controller.isUserInvolved(settlement.payer.phone);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                controller.getSettlementDescription(settlement),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, value, settlement),
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
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

  void _handleMenuAction(BuildContext context, String value, Settlement settlement) {
    switch (value) {
      case 'edit':
        _showEditDialog(context, settlement);
        break;
      case 'delete':
        _showDeleteDialog(context, settlement);
        break;
    }
  }

  void _showEditDialog(BuildContext context, Settlement settlement) {
    final TextEditingController amountController = TextEditingController(
      text: settlement.amount.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Settlement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newAmount = double.tryParse(amountController.text);
                if (newAmount != null && newAmount > 0) {
                  controller.editSettlement(settlement, newAmount);
                  Get.back();
                } else {
                  Get.snackbar(
                    'Error',
                    'Please enter a valid amount',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red.withOpacity(0.1),
                    colorText: Colors.red,
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, Settlement settlement) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Settlement'),
          content: const Text(
            'Are you sure you want to delete this settlement? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                controller.deleteSettlement(settlement);
                Get.back();
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
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