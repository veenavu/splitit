import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';

class MemberController extends GetxController {
  RxList<Contact> contacts = <Contact>[].obs;
  RxSet<int> selectedIndices = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchContacts();
  }

  Future<void> fetchContacts() async {
    if (await FlutterContacts.requestPermission()) {
      List<Contact> fetchedContacts = await FlutterContacts.getContacts(withProperties: true);
      contacts.value = fetchedContacts;
    }
  }

  List<Contact> getSelectedContacts() {
    return selectedIndices.map((index) => contacts[index]).toList();
  }

  void toggleSelection(int index) {
    if (selectedIndices.contains(index)) {
      selectedIndices.remove(index);
    } else {
      selectedIndices.add(index);
    }
  }

  void removeSelectedContact(int index) {
    // Implementation for removing a contact from selected contacts
    final selectedContacts = getSelectedContacts();
    selectedContacts.removeAt(index);
    // Update selectedIndices accordingly
    selectedIndices.clear();
    for (var i = 0; i < contacts.length; i++) {
      if (selectedContacts.contains(contacts[i])) {
        selectedIndices.add(i);
      }
    }
  }
}