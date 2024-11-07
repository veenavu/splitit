import 'package:flutter/material.dart';


class ExpenseScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group One'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton('Settle up', Colors.grey.shade300),
                _buildButton('Balance', Colors.grey.shade300),
                _buildButton('Total', Colors.grey.shade300),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildDateHeader('September 2024'),
                _buildTransactionTile(
                    'Grocery', 'Ameena paid ₹500.00', 'You borrowed', '₹100.00', Colors.red),
                _buildTransactionTile(
                    'Vegetables', 'Sinitha paid ₹2300.00', 'You borrowed', '₹230.00', Colors.red),
                _buildTransactionTile(
                    'Water can', 'You paid ₹620.00', 'You lent', '₹62.00', Colors.green),
                _buildTransactionTile(
                    'Breakfast', 'Saba paid ₹480.00', 'You borrowed', '₹160.00', Colors.red),
                _buildGroupTransaction('Sabu paid Riswan ₹4,580.00'),
                _buildGroupTransaction('Sabu paid Aleena ₹5,200.00'),
                _buildDateHeader('August 2024'),
                _buildTransactionTile(
                    'Uber', 'Saba paid ₹300.00', 'You borrowed', '₹150.00', Colors.red),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Friends'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildButton(String text, Color color) {
    return ElevatedButton(
      onPressed: () {},
      child: Text(text),
      style: ElevatedButton.styleFrom(
        //primary: color,
       // onPrimary: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        date,
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildTransactionTile(
      String title, String subtitle, String status, String amount, Color statusColor) {
    return ListTile(
      leading: Icon(Icons.receipt, color: Colors.black54),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            status,
            style: TextStyle(color: statusColor),
          ),
          Text(
            amount,
            style: TextStyle(
                color: statusColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTransaction(String text) {
    return ListTile(
      leading: Icon(Icons.group, color: Colors.green),
      title: Text(text),
      tileColor: Colors.grey.shade200,
    );
  }
}
