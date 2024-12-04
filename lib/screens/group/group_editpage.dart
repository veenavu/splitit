import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/routes/app_routes.dart';
import 'package:splitit/screens/dashboard/controller/dashboard_controller.dart';
import 'package:splitit/screens/group/widgets/group_editpage_widgets/group_edit_widgets.dart';
import 'package:splitit/screens/group/common_Widget.dart';


class GroupEditPage extends StatefulWidget {
  final Group groups;

  const GroupEditPage({Key? key, required this.groups}) : super(key: key);

  @override
  State<GroupEditPage> createState() => _GroupEditPageState();
}

class _GroupEditPageState extends State<GroupEditPage> {
  late TextEditingController _groupNameController;
  File? _imageFile;
  String? _selectedType;
  String? currentUserPhone;
  final List<String> _groupTypes = ['Trip', 'Home', 'Couple', 'Others'];

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController(text: widget.groups.groupName);
    _selectedType = widget.groups.category;
    if (widget.groups.groupImage.isNotEmpty) {
      _imageFile = File(widget.groups.groupImage);
    }
    final box = Hive.box(ExpenseManagerService.normalBox);
    currentUserPhone = box.get("mobile");
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        setState(() {
          _imageFile = File(pickedImage.path);
          widget.groups.groupImage = pickedImage.path;
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  Future<void> _updateTheGroup() async {
    try {
      if (_groupNameController.text.isEmpty) {
        Get.snackbar(
          'Error',
          'Group name cannot be empty',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
        return;
      }

      if (widget.groups.members.isEmpty) {
        Get.snackbar(
          'Error',
          'Group must have at least one member',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
        return;
      }

      final updatedGroup = Group(
        id: widget.groups.id,
        groupName: _groupNameController.text,
        groupImage: _imageFile?.path ?? widget.groups.groupImage,
        category: _selectedType,
        members: widget.groups.members,
        expenses: widget.groups.expenses,
        categories: widget.groups.categories,
        createdAt: widget.groups.createdAt,
      );

      await ExpenseManagerService.updateGroup(updatedGroup);
      Get.find<DashboardController>().loadGroups();

      Get.snackbar(
        'Success',
        'Group updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      Get.offAllNamed(Routes.dashboard);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update group: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  void _handleDeleteMember(Member member, int index) {
    GroupEditWidgets.showDeleteMemberDialog(
      context: context,
      member: member,
      index: index,
      group: widget.groups,
      onMemberRemoved: () {
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
          tooltip: 'Back',
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
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            tooltip: 'Save Changes',
            onPressed: _updateTheGroup,
          ),
        ],
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GroupEditWidgets.buildGroupImagePicker(
                imageFile: _imageFile,
                onTap: _pickImage,
              ),
              const SizedBox(height: 24),
              GroupEditWidgets.buildGroupNameField(
                controller: _groupNameController,
              ),
              const SizedBox(height: 24),
              const Text(
                'Group Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: _groupTypes.map((type) => GroupEditWidgets.buildGroupTypeButton(
                  type: type,
                  selectedType: _selectedType,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = selected ? type : null;
                    });
                  },
                )).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Members (${widget.groups.members.length})",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GroupEditWidgets.buildMembersList(
                members: widget.groups.members,
                currentUserPhone: currentUserPhone,
                onDeleteMember: _handleDeleteMember,
                context: context,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showMemberAddingBottomSheet(
            context: context,
            onContactsSelected: (contacts) async {
              if (contacts != null && contacts.isNotEmpty) {
                setState(() {
                  for (var contact in contacts) {
                    final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
                    bool memberExists = widget.groups.members.any((member) => member.phone == phone);

                    if (!memberExists) {
                      widget.groups.members.add(Member(
                        name: contact.displayName,
                        phone: phone,
                      ));
                    } else {
                      Get.snackbar(
                        'Duplicate Member',
                        '${contact.displayName} is already in the group',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        colorText: Colors.orange,
                      );
                    }
                  }
                });
              }
            },
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Members'),
        backgroundColor: Colors.purple,
      ),
    );
  }
}