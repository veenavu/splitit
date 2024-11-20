import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
class MemberAdding extends StatefulWidget {
  const MemberAdding({super.key});
  @override
  State<MemberAdding> createState() => _MemberAddingState();
}
class _MemberAddingState extends State<MemberAdding> {
  List<Contact> contacts = [];
  final Set<int> selectedIndices = {}; // Track selected contact indices
  final List<String> _groupTypes = ['Trip', 'Home', 'Couple', 'Others'];
  @override
  void initState() {
    super.initState();
    _fetchContacts(); // Automatically fetch contacts on initialization
  }
  Future<void> _fetchContacts() async {
    if (await FlutterContacts.requestPermission()) {
      List<Contact> fetchedContacts = await FlutterContacts.getContacts(withProperties: true);
      setState(() => contacts = fetchedContacts);
    } else {
      setState(() => contacts = []);
    }
  }
  List<Contact> getSelectedContacts() {
    return selectedIndices.map((index) => contacts[index]).toList();
  }
  void navigateToSelectedContactsPage() {
    final selectedContacts = getSelectedContacts();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectedContactsPage(selectedContacts: selectedContacts),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context), // Navigate back
          tooltip: 'Go Back',
        ),
        title: const Text(
          'Select Contacts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true, // Centers the title for a balanced appearance
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.white),
            tooltip: 'Proceed to Selected Contacts',
            onPressed: navigateToSelectedContactsPage,
          ),
        ],
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
      ),

      body: contacts.isNotEmpty
          ? ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          final isSelected = selectedIndices.contains(index);

          return GestureDetector(
            onTap: () => setState(() {
              isSelected
                  ? selectedIndices.remove(index)
                  : selectedIndices.add(index);
            }),
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: isSelected ? Colors.purple.shade100 : Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: contact.photo != null
                      ? MemoryImage(contact.photo!)
                      : null,
                  child: contact.photo == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                  backgroundColor: isSelected ? Colors.purple : Colors.grey.shade300,
                ),
                title: Text(
                  contact.displayName ?? 'No Name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isSelected ? Colors.purple.shade900 : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  contact.phones.isNotEmpty
                      ? contact.phones.first.number
                      : 'No Phone',
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? Colors.purple.shade700 : Colors.grey,
                  ),
                ),
                trailing: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.purple : Colors.grey,
                ),
              ),
            ),
          );
        },
      )

          : Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No Contacts Available or Permission Denied'),
        ),
      ),
    );
  }
}


class SelectedContactsPage extends StatelessWidget {
  final List<Contact> selectedContacts;


  const SelectedContactsPage({Key? key, required this.selectedContacts}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selected Contacts'),
      ),
      body:ListView.builder(
        itemCount: selectedContacts.length,
        itemBuilder: (context, index) {
          final contact = selectedContacts[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundImage: contact.photo != null ? MemoryImage(contact.photo!) : null,
                  backgroundColor: Colors.grey.shade200,
                  child: contact.photo == null
                      ? const Icon(Icons.person, size: 28, color: Colors.grey)
                      : null,
                ),
                title: Text(
                  contact.displayName ?? 'No Name',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  contact.phones.isNotEmpty ? contact.phones.first.number : 'No Phone',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    // Add your delete action here
                    // setState(() {
                    //   selectedContacts.removeAt(index);
                    // });
                  },
                  tooltip: 'Remove Contact',
                ),
              ),
            ),
          );
        },
      )

    );
  }
}
