import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class MemberAdding extends StatefulWidget {
  const MemberAdding({Key? key}) : super(key: key);

  @override
  State<MemberAdding> createState() => _MemberAddingState();
}

class _MemberAddingState extends State<MemberAdding> {
  List<Contact> contacts = [];
  final Set<int> selectedIndices = {}; // Track selected contact indices

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
        title: Text('Select Contacts'),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: navigateToSelectedContactsPage,
          ),
        ],
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
            child: Container(
              color: isSelected ? Colors.blueAccent.withOpacity(0.5) : Colors.transparent,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: contact.photo != null
                      ? MemoryImage(contact.photo!)
                      : null,
                  child: contact.photo == null ? Icon(Icons.person) : null,
                ),
                title: Text(
                  contact.displayName ?? 'No Name',
                  style: TextStyle(color: isSelected ? Colors.white : Colors.black),
                ),
                subtitle: Text(
                  contact.phones.isNotEmpty ? contact.phones.first.number : 'No Phone',
                  style: TextStyle(color: isSelected ? Colors.white70 : Colors.black54),
                ),
                trailing: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? Colors.white : Colors.grey,
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
      body: ListView.builder(
        itemCount: selectedContacts.length,
        itemBuilder: (context, index) {
          final contact = selectedContacts[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: contact.photo != null ? MemoryImage(contact.photo!) : null,
              child: contact.photo == null ? Icon(Icons.person) : null,
            ),
            title: Text(contact.displayName ?? 'No Name'),
            subtitle: Text(contact.phones.isNotEmpty ? contact.phones.first.number : 'No Phone'),
          );
        },
      ),
    );
  }
}
