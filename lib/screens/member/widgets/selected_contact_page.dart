import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/screens/member/controller/member_controller.dart';

class SelectedContactsPage extends StatelessWidget {
  const SelectedContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MemberController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selected Contacts'),
      ),
      body: Obx(() {
        final selectedContacts = controller.getSelectedContacts();
        return ListView.builder(
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
                    child: contact.photo == null ? const Icon(Icons.person, size: 28, color: Colors.grey) : null,
                  ),
                  title: Text(
                    contact.displayName,
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
                    onPressed: () => controller.removeSelectedContact(index),
                    tooltip: 'Remove Contact',
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
