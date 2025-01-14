import 'package:flutter/material.dart';
import '../../../../modelClass/models.dart';

class ExpenseSplitDetailsCard extends StatelessWidget {
  final Expense expense;

  const ExpenseSplitDetailsCard({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Split Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    expense.divisionMethod == DivisionMethod.equal ? 'Split Equally' : 'Custom Split',
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expense.splits.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.purple.shade50,
                thickness: 1,
              ),
              itemBuilder: (context, index) {
                final split = expense.splits[index];
                final isPayer = split.member.phone == expense.paidByMember.phone;
                double netAmount = _calculateNetAmount(split, isPayer);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPayer ? Colors.green.shade100 : Colors.purple.shade100,
                    child: Icon(
                      isPayer ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isPayer ? Colors.green : Colors.purple,
                    ),
                  ),
                  title: Text(
                    split.member.name + (isPayer ? ' (Paid)' : ''),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isPayer ? 'gets back' : 'owes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '₹${netAmount.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPayer ? Colors.green : Colors.purple,
                        ),
                      ),
                      if (expense.divisionMethod == DivisionMethod.percentage && split.percentage != null)
                        Text(
                          '${split.percentage!.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  double _calculateNetAmount(ExpenseSplit split, bool isPayer) {
    if (isPayer) {
      return expense.totalAmount - split.amount;
    } else {
      return -split.amount;
    }
  }
}