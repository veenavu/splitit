import 'package:flutter/material.dart';
import '../../../../modelClass/models.dart';

class ExpenseAdditionalInfoCard extends StatelessWidget {
  final Expense expense;

  const ExpenseAdditionalInfoCard({Key? key, required this.expense}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.purple.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Group',
              expense.group?.groupName ?? 'Personal Expense',
              Icons.group,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Date',
              _formatDate(expense.createdAt),
              Icons.calendar_today,
            ),
            if (expense.note != null && expense.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                'Note',
                expense.note!,
                Icons.note,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.purple.shade400,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}