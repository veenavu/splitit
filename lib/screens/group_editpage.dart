import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';

import 'package:image_picker/image_picker.dart';
import 'package:splitit/modelClass/models.dart' as mod;
import 'package:splitit/utils/common_functions.dart';

import '../DatabaseHelper/hive_services.dart';

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

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController(text: widget.groups.groupName);
    _selectedType = widget.groups.category;
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Group'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.black, size: 28),
            onPressed: _updateTheGroup,
          ),
          SizedBox(
            width: 20,
          ),
        ],
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
                    return ListTile(
                        leading: const CircleAvatar(),
                        title: Text(widget.groups.members[index].name));
                  }),
            )
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
                      phone: ''); // Add phone if available
                }).toList();

                // Filter out any selected members that are already in the group
                List<mod.Member> uniqueMembers =
                    selectedMembers.where((newMember) {
                  return !widget.groups.members.any((existingMember) =>
                      existingMember.name ==
                      newMember
                          .name); // Adjust as needed, e.g., `name` or `phone`
                }).toList();

                // Update the members list with the unique, non-duplicate entries
                setState(() {
                  widget.groups.members.addAll(uniqueMembers);
                });
              }
            },
          );
        },
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
