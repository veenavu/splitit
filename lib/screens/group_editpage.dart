import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';

import 'package:image_picker/image_picker.dart';
import 'package:splitit/modelClass/models.dart' as mod;
import 'package:splitit/utils/common_functions.dart';

import '../DatabaseHelper/hive_services.dart';
import '../modelClass/models.dart';

class GroupEditPage extends StatefulWidget {
  final mod.Group groups;

  GroupEditPage({super.key, required this.groups,});

  @override
  State<GroupEditPage> createState() => _GroupEditPageState();
}

class _GroupEditPageState extends State<GroupEditPage> {
  late TextEditingController _groupNameController = TextEditingController();
  File? _imageFile;
  String? _selectedType;
  final List<String> _groupTypes = ['Trip', 'Home', 'Couple', 'Others'];

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
        // Optionally update the group image path if needed
        widget.groups.groupImage = pickedImage.path;
      });
    }
  }
  Future<void> _updateTheGroup() async {
    ExpenseManagerService.updateGroup(widget.groups);
    Navigator.pop(context, true);
  }

  Widget _buildGroupTypeButton(String type) {
    return RawChip(
      label: Text(
        type,
        style: TextStyle(
          color: _selectedType == type ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      selected: _selectedType == type,
      onSelected: (bool selected) {
        setState(() {
          _selectedType = selected ? type : null;
        });
      },
      selectedColor: Colors.purple, // Highlight color for selected chip
      backgroundColor: Colors.grey.shade200, // Neutral background for unselected chips
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded edges for modern style
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Enhanced spacing
      showCheckmark: false, // Disables the tick mark on selection
    );
  }




  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController(text: widget.groups.groupName);
    _selectedType = widget.groups.category;
  }
  void _showDeleteMemberDialog(Member member, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Member"),
          content: Text("Are you sure you want to delete ${member.name}?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await _deleteMember(member, index);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }
  Future<void> _deleteMember(Member member, int index) async {
    setState(() {
      widget.groups.members.removeAt(index); // Remove the member from the list
    });

    // Update the group in Hive
    await ExpenseManagerService.updateGroup(widget.groups);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${member.name} has been deleted.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Group',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.purple,
        elevation: 4,
        centerTitle: true, // Centers the title for a balanced look
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.white),
            tooltip: 'Save Changes',
            onPressed: _updateTheGroup,
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.deepPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16), // Adds a curve to the bottom of the AppBar
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(
              height: 30,
            ),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.file(
                    File(widget.groups.groupImage),
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 50),
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

            const SizedBox(height: 30),
            Align(
                alignment: Alignment.centerLeft,
                child: Text("Members: ${widget.groups.members.length}")),
            const SizedBox(
              height: 5,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.groups.members.length,
                itemBuilder: (context, index) {
                  final member = widget.groups.members[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        onLongPress: () => _showDeleteMemberDialog(member, index),
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.shade100,
                          child: const Icon(
                            Icons.person,
                            color: Colors.purple,
                          ),
                        ),
                        title: Text(
                          member.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        // subtitle: Text(
                        //   member.phone.isNotEmpty ? member.phone : "No phone number available",
                        //   style: const TextStyle(
                        //     fontSize: 14,
                        //     color: Colors.grey,
                        //   ),
                        // ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.purple,
                          ),
                          tooltip: 'Delete Member',
                          onPressed: () => _showDeleteMemberDialog(member, index),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),


          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showMemberAddingBottomSheet(
            context: context,
            onContactsSelected: (contacts) {
              if (contacts != null && contacts.isNotEmpty) {
                // Convert selected contacts to `mod.Member` objects
                List<mod.Member> selectedMembers = contacts.map((contact) {
                  return mod.Member(
                    name: contact.displayName,
                    phone: contact.phones.isNotEmpty ? contact.phones.first.number : '',
                  );
                }).toList();

                // Filter out members already in the group
                List<mod.Member> uniqueMembers = selectedMembers.where((newMember) {
                  return !widget.groups.members.any((existingMember) =>
                  existingMember.name == newMember.name);
                }).toList();

                // Add unique members to the group
                setState(() {
                  widget.groups.members.addAll(uniqueMembers);
                });
              }
            },
          );
        },
        label: const Row(
          children: [
            Icon(
              Icons.person_add,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(
              "Add Members",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add, color: Colors.white), // Optional Icon
        tooltip: 'Add new members', // Accessibility and hints
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners for a modern look
        ),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

    );
  }
}
