import 'package:flutter/material.dart';

class TotalOwed extends StatelessWidget {
  final String amount;

  const TotalOwed({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              color: amount.contains("owe")
                  ? Colors.red
                  : amount.contains("settle")
                  ? Colors.grey
                  : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
