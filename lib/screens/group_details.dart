import 'package:flutter/material.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/group_settings.dart';

class GroupDetails extends StatelessWidget {
  final Group groupItem;

  const GroupDetails({super.key, required this.groupItem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupItem.groupName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => GroupSettings(group: groupItem)));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
                _buildTransactionTile('Grocery', 'Ameena paid ₹500.00', 'You borrowed', '₹100.00', Colors.red),
                _buildTransactionTile('Vegetables', 'Sinitha paid ₹2300.00', 'You borrowed', '₹230.00', Colors.red),
                _buildTransactionTile('Water can', 'You paid ₹620.00', 'You lent', '₹62.00', Colors.green),
                _buildTransactionTile('Breakfast', 'Saba paid ₹480.00', 'You borrowed', '₹160.00', Colors.red),
                _buildGroupTransaction('Sabu paid Riswan ₹4,580.00'),
                _buildGroupTransaction('Sabu paid Aleena ₹5,200.00'),
                _buildDateHeader('August 2024'),
                _buildTransactionTile('Uber', 'Saba paid ₹300.00', 'You borrowed', '₹150.00', Colors.red),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Friends'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
        selectedItemColor: Color(0xff5f0967),
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
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildTransactionTile(String title, String subtitle, String status, String amount, Color statusColor) {
    return ListTile(
      leading: const Icon(Icons.receipt, color: Colors.black54),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTransaction(String text) {
    return ListTile(
      leading: const Icon(Icons.group, color: Colors.green),
      title: Text(text),
      tileColor: Colors.grey.shade200,
    );
  }
}
