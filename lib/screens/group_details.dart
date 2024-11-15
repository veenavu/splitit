import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/group_settings.dart';

class GroupDetails extends StatefulWidget {
  final Group groupItem;

  const GroupDetails({super.key, required this.groupItem});

  @override
  State<GroupDetails> createState() => _GroupDetailsState();
}

class _GroupDetailsState extends State<GroupDetails> {
  List<Expense> expenses = [];
  Expense? myExpense;
  String? phoneNumber;

  Future<void> getAllExpenses() async {
    final box = Hive.box(ExpenseManagerService.normalBox);
    phoneNumber = box.get("mobile");

    final groupExpenses = ExpenseManagerService.getExpensesByGroup(widget.groupItem);

    setState(() {
      expenses = groupExpenses;
    });
  }

  @override
  void initState() {
    getAllExpenses();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupItem.groupName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => GroupSettings(group: widget.groupItem)));
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
            child: ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (BuildContext context, int index) {
                bool isYou =phoneNumber == expenses[index].paidByMember.phone;
                return GestureDetector(
                  onLongPress: ()async{

                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Delete Expense"),
                          content: const Text("Do you want to delete this expense?"),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () async{
                                await ExpenseManagerService.deleteExpense(expenses[index]);
                                setState(() {
                                  expenses = ExpenseManagerService.getExpensesByGroup(widget.groupItem);
                                });
                                Navigator.of(context).pop();
                              },
                              child: const Text("Yes"),
                            ),
                          ],
                        );
                      },
                    );

                  },
                  child: _buildTransactionTile(
                      title: expenses[index].description,
                      subtitle:
                          '${isYou ? "You" : expenses[index].paidByMember.name} paid ₹${expenses[index].totalAmount.toString()}',
                      status: isYou ? 'You lent' : 'You borrowed',
                      amount: expenses[index].splits
                          .firstWhere((es) => es.member.phone == phoneNumber)
                          .amount
                          .toString(),
                      statusColor:isYou ? Colors.green : Colors.red),
                );

              },
              // children: [
              //   _buildDateHeader('September 2024'),
              //   _buildTransactionTile('Grocery', 'Ameena paid ₹500.00', 'You borrowed', '₹100.00', Colors.red),
              //   _buildTransactionTile('Vegetables', 'Sinitha paid ₹2300.00', 'You borrowed', '₹230.00', Colors.red),
              //   _buildTransactionTile('Water can', 'You paid ₹620.00', 'You lent', '₹62.00', Colors.green),
              //   _buildTransactionTile('Breakfast', 'Saba paid ₹480.00', 'You borrowed', '₹160.00', Colors.red),
              //   _buildGroupTransaction('Sabu paid Riswan ₹4,580.00'),
              //   _buildGroupTransaction('Sabu paid Aleena ₹5,200.00'),
              //   _buildDateHeader('August 2024'),
              //   _buildTransactionTile('Uber', 'Saba paid ₹300.00', 'You borrowed', '₹150.00', Colors.red),
              // ],
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

  Widget _buildButton(String text, Color color, {VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        //primary: color,
        // onPrimary: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(text),
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

  Widget _buildTransactionTile({required String title, required String subtitle, required String status, required String amount, required Color statusColor}) {
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
