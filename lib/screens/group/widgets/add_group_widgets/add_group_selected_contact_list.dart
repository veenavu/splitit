import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class SelectedContactsList extends StatelessWidget {
  final List<Contact> contacts;
  final Function(int) onRemove;

  const SelectedContactsList({
    super.key,
    required this.contacts,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: contact.photo != null ? MemoryImage(contact.photo!) : null,
            child: contact.photo == null ? const Icon(Icons.person) : null,
          ),
          title: Text(contact.displayName ?? 'No Name'),
          subtitle: Text(contact.phones.isNotEmpty ? contact.phones.first.number : 'No Phone'),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            color: Colors.red,
            onPressed: () => onRemove(index),
          ),
        );
      },
    );
  }
}