import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/screens/member/controller/member_controller.dart';
import 'package:splitit/screens/member/widgets/selected_contact_page.dart';

class MemberAddingPage extends GetView<MemberController> {
  const MemberAddingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
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
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.white),
            tooltip: 'Proceed to Selected Contacts',
            onPressed: () => Get.to(() => const SelectedContactsPage()),
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
      body: Obx(() => controller.contacts.isNotEmpty
          ? ListView.builder(
              itemCount: controller.contacts.length,
              itemBuilder: (context, index) {
                final contact = controller.contacts[index];
                final isSelected = controller.selectedIndices.contains(index);

                return GestureDetector(
                  onTap: () => controller.toggleSelection(index),
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: isSelected ? Colors.purple.shade100 : Colors.white,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: contact.photo != null ? MemoryImage(contact.photo!) : null,
                        backgroundColor: isSelected ? Colors.purple : Colors.grey.shade300,
                        child: contact.photo == null ? const Icon(Icons.person, color: Colors.white) : null,
                      ),
                      title: Text(
                        contact.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSelected ? Colors.purple.shade900 : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        contact.phones.isNotEmpty ? contact.phones.first.number : 'No Phone',
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
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No Contacts Available or Permission Denied'),
              ),
            )),
    );
  }
}
