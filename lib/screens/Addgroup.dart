import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:splitit/modelClass/models.dart' as custom;
import 'package:splitit/DatabaseHelper/hive_services.dart';

import 'GroupMainPage.dart';

class AddNewGroupPage extends StatefulWidget {
  const AddNewGroupPage({super.key});

  @override
  _AddNewGroupPageState createState() => _AddNewGroupPageState();
}

class _AddNewGroupPageState extends State<AddNewGroupPage> {
  //ExpenseManagerService service=ExpenseManagerService();
  final TextEditingController _groupNameController = TextEditingController();
  String? _selectedType;
  String? _imagePath;
  List<Contact> selectedContacts = [];
  final List<String> _groupTypes = ['Trip', 'Home', 'Couple', 'Others'];

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      String? savedPath = await _saveImagePath(File(pickedFile.path));
      setState(() {
        _imagePath = savedPath;
      });
    }
  }

  Future<String?> _saveImagePath(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png';
      final savedImage = await imageFile.copy(filePath);
      return savedImage.path;
    } catch (e) {
      print("Error saving image: $e");
      return null;
    }
  }

  void _showMemberAddingBottomSheet() async {
    final result = await showModalBottomSheet<List<Contact>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => MemberAdding(
        onContactsSelected: (contacts) {
          Navigator.pop(context, contacts);
        },
      ),
    );

    if (result != null) {
      setState(() {
        selectedContacts = result;
      });
    }
  }

  Future<List<custom.Member>> _getMembersFromContacts() async {
    return await Future.wait(selectedContacts.map((contact) async {
      String? imagePath;
      if (contact.photo != null) {
        imagePath = await _saveContactImage(
            contact.photo! as File, contact.displayName ?? 'contact_image');
      }

      return custom.Member(
        name: contact.displayName ?? 'Unnamed',
        phone: contact.phones.isNotEmpty
            ? contact.phones.first.number
            : 'No Phone',
        imagePath: imagePath,
      );
    }).toList());
  }

  Future<String?> _saveContactImage(File imageFile, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName.png';
    final savedImage = await imageFile.copy(filePath);
    return savedImage.path;
  }

  Future<void> _saveGroup() async {
    await ExpenseManagerService.initHive();
    if (_groupNameController.text.isEmpty ||
        _imagePath == null ||
        _selectedType == null ||
        selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields and add members")),
      );
      return;
    }

    List<custom.Member> members = await _getMembersFromContacts();

    custom.Group group = custom.Group(
      groupName: _groupNameController.text,
      groupImage: _imagePath!,
      category: _selectedType,
      members: members,
    );

    await ExpenseManagerService.saveTheGroup(group);
    print("Navigating to GroupsScreen...");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GroupsScreen()), // Replace with your target screen widget
    );


    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(content: Text("Group saved successfully!")),
    // );
    //
    // Navigator.pop(context);

  }

  Widget _buildGroupTypeButton(String type) {
    return ChoiceChip(
      label: Text(type),
      selected: _selectedType == type,
      onSelected: (bool selected) {
        setState(() {
          _selectedType = selected ? type : null;
        });
      },
      selectedColor: const Color(0xFFC9BFBF),
      backgroundColor: Colors.transparent,
      labelStyle: TextStyle(
        color: _selectedType == type ? Colors.black : Colors.black,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  void _removeContact(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Member"),
          content: const Text("Do you want to delete this member?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedContacts.removeAt(index);
                });
                Navigator.of(context).pop();
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF5F0967),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 35),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Add new group",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white, size: 35),
            onPressed: _saveGroup,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _imagePath != null ? FileImage(File(_imagePath!)) : null,
                backgroundColor: const Color(0xFFE2CBE1),
                child: _imagePath == null
                    ? const Icon(Icons.add_photo_alternate,
                        size: 50, color: Color(0xFF5F0967))
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                hintText: 'Group name',
                filled: true,
                fillColor: const Color(0xFFE2CBE1),
                prefixIcon: const Icon(Icons.person, color: Color(0xFF5F0967)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Type',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5F0967)),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              children: _groupTypes
                  .map((type) => _buildGroupTypeButton(type))
                  .toList(),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: selectedContacts.length,
                itemBuilder: (context, index) {
                  final contact = selectedContacts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: contact.photo != null
                          ? FileImage(contact.photo! as File)
                          : null,
                      child: contact.photo == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(contact.displayName ?? 'No Name'),
                    subtitle: Text(contact.phones.isNotEmpty
                        ? contact.phones.first.number
                        : 'No Phone'),
                    onLongPress: () => _removeContact(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showMemberAddingBottomSheet,
        label: const Row(
          children: [
            Icon(Icons.person_add, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Add Members",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.purple,
      ),
    );
  }
}

class MemberAdding extends StatefulWidget {
  final ValueChanged<List<Contact>> onContactsSelected;

  MemberAdding({required this.onContactsSelected});

  @override
  _MemberAddingState createState() => _MemberAddingState();
}

class _MemberAddingState extends State<MemberAdding> {
  List<Contact> contacts = [];
  Set<String> selectedContactIds = {};

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    if (await FlutterContacts.requestPermission()) {
      List<Contact> fetchedContacts =
          await FlutterContacts.getContacts(withProperties: true);
      setState(() => contacts = fetchedContacts);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              final selectedContacts = contacts
                  .where((contact) => selectedContactIds.contains(contact.id))
                  .toList();
              widget.onContactsSelected(selectedContacts);
            },
          ),
        ],
      ),
      body: contacts.isNotEmpty
          ? ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                final isSelected = selectedContactIds.contains(contact.id);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      isSelected
                          ? selectedContactIds.remove(contact.id)
                          : selectedContactIds.add(contact.id);
                    });
                  },
                  child: Container(
                    color: isSelected
                        ? Colors.blueAccent.withOpacity(0.5)
                        : Colors.transparent,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: contact.photo != null
                            ? MemoryImage(contact.photo!)
                            : null,
                        child:
                            contact.photo == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(
                        contact.displayName ?? 'No Name',
                        style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black),
                      ),
                      subtitle: Text(
                        contact.phones.isNotEmpty
                            ? contact.phones.first.number
                            : 'No Phone',
                        style: TextStyle(
                            color:
                                isSelected ? Colors.white70 : Colors.black54),
                      ),
                      trailing: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                      //onLongPress: () => _removeContact(index),
                    ),
                  ),
                );
              },
            )
          : const Center(child: Text('No contacts found or permission denied')),
    );
  }
}
