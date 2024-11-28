import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/routes/app_routes.dart';
import 'package:splitit/screens/dashboard/controller/dashboard_controller.dart';
import 'package:splitit/utils/common_functions.dart';

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
    // Get current user's phone number
    final box = Hive.box(ExpenseManagerService.normalBox);
    currentUserPhone = box.get("mobile");
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  // Image picker function
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

  // Update group function
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

      widget.groups.groupName = _groupNameController.text;
      widget.groups.category = _selectedType;

      await ExpenseManagerService.updateGroup(widget.groups);

      Get.find<DashboardController>().loadGroups();
      Get.back(result: true);

      Get.snackbar(
        'Success',
        'Group updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
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

  // Delete member dialog
  void _showDeleteMemberDialog(Member member, int index) {
    // Check if this is the current user
    if (member.phone == currentUserPhone) {
      Get.snackbar(
        'Cannot Delete',
        'You cannot remove yourself from the group',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            "Delete ${member.name}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Choose how to handle this member's expenses:",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                icon: Icons.cancel_outlined,
                label: "Cancel",
                description: "Keep member in the group",
                onTap: () => Get.back(),
                color: Colors.grey,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                icon: Icons.compare_arrows,
                label: "Migrate Expenses",
                description: "Convert to individual expenses",
                onTap: () => _migrateMemberExpenses(member, index),
                color: Colors.orange,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                icon: Icons.delete_forever,
                label: "Force Delete",
                description: "Remove member and their expenses",
                onTap: () => _forceDeleteMember(member, index),
                color: Colors.red,
              ),

              const SizedBox(height: 8),
              _buildActionButton(
                icon: Icons.person_remove_alt_1,
                label: "Remove member with unchanged Expense",
                description: "Convert to individual expenses",
                onTap: () => _RemoveMemberUnchangedExpense(member, index),
                color: Colors.red,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.groups.members.length,
      itemBuilder: (context, index) {
        final member = widget.groups.members[index];
        final isCurrentUser = member.phone == currentUserPhone;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCurrentUser ? Colors.purple : Colors.purple.shade100,
              child: Text(
                member.name[0].toUpperCase(),
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              member.name + (isCurrentUser ? ' (You)' : ''),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              member.phone,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            trailing: isCurrentUser ? null : IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              onPressed: () => _showDeleteMemberDialog(member, index),
            ),
          ),
        );
      },
    );
  }



  Future<void> _forceDeleteMember(Member member, int index) async {
    try {
      // Get all expenses for the group
      final expenses = ExpenseManagerService.getExpensesByGroup(widget.groups);

      // Handle each expense that involves the member being deleted
      for (var expense in expenses) {
        bool memberIsPayer = expense.paidByMember.phone == member.phone;
        bool memberInSplits = expense.splits.any((split) => split.member.phone == member.phone);

        if (memberIsPayer || memberInSplits) {
          // Get the split amount for the member being deleted
          double memberSplitAmount = 0.0;
          for (var split in expense.splits) {
            if (split.member.phone == member.phone) {
              memberSplitAmount = split.amount;
              break;
            }
          }

          // Calculate new total amount by subtracting member's split
          double newTotalAmount = expense.totalAmount - memberSplitAmount;

          if (memberIsPayer) {
            // If deleted member was the payer, find a new payer from remaining members
            Member? newPayer = expense.splits
                .where((split) => split.member.phone != member.phone)
                .firstOrNull
                ?.member;

            if (newPayer != null) {
              // Create new splits excluding the deleted member
              List<ExpenseSplit> newSplits = expense.splits
                  .where((split) => split.member.phone != member.phone)
                  .map((split) {
                // Calculate new split amount proportionally
                double ratio = split.amount / (expense.totalAmount - memberSplitAmount);
                return ExpenseSplit(
                  member: split.member,
                  amount: newTotalAmount * ratio,
                  percentage: split.percentage,
                );
              })
                  .toList();

              // Update the expense with new payer and adjusted splits
              await ExpenseManagerService.updateExpense(
                expense: expense,
                totalAmount: newTotalAmount,
                divisionMethod: expense.divisionMethod,
                paidByMember: newPayer,
                involvedMembers: newSplits.map((split) => split.member).toList(),
                customAmounts: newSplits.map((split) => split.amount).toList(),
                description: expense.description,
                group: widget.groups,
              );
            } else {
              // If no other members in splits, delete the expense
              await ExpenseManagerService.deleteExpense(expense);
            }
          } else if (memberInSplits) {
            // If member was only in splits, create new splits without the member
            List<ExpenseSplit> newSplits = expense.splits
                .where((split) => split.member.phone != member.phone)
                .map((split) {
              // Calculate new split amount proportionally
              double ratio = split.amount / (expense.totalAmount - memberSplitAmount);
              return ExpenseSplit(
                member: split.member,
                amount: newTotalAmount * ratio,
                percentage: split.percentage,
              );
            })
                .toList();

            // Update the expense with adjusted total and splits
            await ExpenseManagerService.updateExpense(
              expense: expense,
              totalAmount: newTotalAmount,
              divisionMethod: expense.divisionMethod,
              paidByMember: expense.paidByMember,
              involvedMembers: newSplits.map((split) => split.member).toList(),
              customAmounts: newSplits.map((split) => split.amount).toList(),
              description: expense.description,
              group: widget.groups,
            );
          }
        }
      }

      // Remove member from group
      List<Member> updatedMembers = List<Member>.from(widget.groups.members);
      updatedMembers.removeAt(index);
      widget.groups.members = updatedMembers;

      // Update group in storage
      await ExpenseManagerService.updateGroup(widget.groups);

      // Update UI
      setState(() {});

      Get.back(); // Close dialog
      Get.snackbar(
        'Success',
        '${member.name} has been removed and expenses have been adjusted',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
    } catch (e) {
      Get.back(); // Close dialog
      Get.snackbar(
        'Error',
        'Failed to delete member: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

// Migrate expenses implementation
  Future<void> _migrateMemberExpenses(Member member, int index) async {
    try {
      // Get all expenses for the group
      final expenses = ExpenseManagerService.getExpensesByGroup(widget.groups);

      // Handle each expense involving this member
      for (var expense in expenses) {
        if (expense.paidByMember.phone == member.phone ||
            expense.splits.any((split) => split.member.phone == member.phone)) {
          // Convert group expense to individual expense
          await _convertToIndividualExpense(expense, member);
          // Delete the original group expense
          await ExpenseManagerService.deleteExpense(expense);
        }
      }

      // Remove member from group
      List<Member> updatedMembers = List<Member>.from(widget.groups.members);
      updatedMembers.removeAt(index);
      widget.groups.members = updatedMembers;

      // Update group in storage
      await ExpenseManagerService.updateGroup(widget.groups);

      // Update UI
      setState(() {});

      Get.back(); // Close dialog
      Get.snackbar(
        'Success',
        '${member.name} removed and expenses migrated to individual',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
    } catch (e) {
      Get.back(); // Close dialog
      Get.snackbar(
        'Error',
        'Failed to migrate expenses: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }


  Future<void> _RemoveMemberUnchangedExpense(Member member, int index) async {
    try {
      // Get all expenses for the group
      final expenses = ExpenseManagerService.getExpensesByGroup(widget.groups);

      // Handle each expense
      for (var expense in expenses) {
        bool isMemberPayer = expense.paidByMember.phone == member.phone;
        bool isMemberInSplits = expense.splits.any((split) => split.member.phone == member.phone);

        if (isMemberPayer) {
          // If member is payer, delete the expense as it no longer makes sense to keep
          await ExpenseManagerService.deleteExpense(expense);
          continue;
        }

        if (isMemberInSplits) {
          // Get member's split amount that needs to be redistributed
          double amountToRedistribute = expense.splits
              .firstWhere((split) => split.member.phone == member.phone)
              .amount;

          // Get remaining members (excluding the deleted member)
          List<ExpenseSplit> remainingSplits = expense.splits
              .where((split) => split.member.phone != member.phone)
              .toList();

          // Calculate total amount of remaining splits
          double totalRemainingSplitsAmount = remainingSplits.fold(
            0.0,
                (sum, split) => sum + split.amount,
          );

          // Create new splits with redistributed amount
          List<ExpenseSplit> newSplits = remainingSplits.map((split) {
            // Calculate proportion of this split compared to total remaining
            double proportion = split.amount / totalRemainingSplitsAmount;

            // Add proportional share of redistributed amount
            double newAmount = split.amount + (amountToRedistribute * proportion);

            return ExpenseSplit(
              member: split.member,
              amount: newAmount,
              percentage: (newAmount / expense.totalAmount) * 100,
            );
          }).toList();

          // Update the expense with new splits
          await ExpenseManagerService.updateExpense(
            expense: expense,
            totalAmount: expense.totalAmount, // Keep original total
            divisionMethod: DivisionMethod.unequal, // Switch to unequal as splits are now custom
            paidByMember: expense.paidByMember,
            involvedMembers: newSplits.map((split) => split.member).toList(),
            customAmounts: newSplits.map((split) => split.amount).toList(),
            description: expense.description,
            group: widget.groups,
          );
        }
      }

      // Remove member from group
      List<Member> updatedMembers = List<Member>.from(widget.groups.members);
      updatedMembers.removeAt(index);
      widget.groups.members = updatedMembers;

      // Update group in storage
      await ExpenseManagerService.updateGroup(widget.groups);

      // Update UI
      setState(() {});

      Get.back(); // Close dialog
      Get.snackbar(
        'Success',
        '${member.name} has been removed and their expenses have been redistributed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
    } catch (e) {
      Get.back(); // Close dialog
      Get.snackbar(
        'Error',
        'Failed to remove member: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  // Helper method to convert group expense to individual expense
  Future<void> _convertToIndividualExpense(Expense groupExpense, Member member) async {
    // Calculate the individual amount for this member
    double memberAmount = 0.0;

    if (groupExpense.paidByMember.phone == member.phone) {
      // If member is the payer, they get credited
      memberAmount = groupExpense.splits
          .where((split) => split.member.phone != member.phone)
          .fold(0.0, (sum, split) => sum + split.amount);
    } else {
      // If member owes money
      final memberSplit = groupExpense.splits
          .firstWhere((split) => split.member.phone == member.phone);
      memberAmount = -memberSplit.amount; // Negative because they owe this amount
    }

    if (memberAmount != 0) {
      // Create a new individual expense
      await ExpenseManagerService.createExpense(
        totalAmount: memberAmount.abs(),
        divisionMethod: DivisionMethod.equal,
        paidByMember: memberAmount > 0 ? member : groupExpense.paidByMember,
        involvedMembers: [
          memberAmount > 0 ? groupExpense.paidByMember : member
        ],
        description: "${groupExpense.description} (Migrated)",
        group: null, // No group for individual expense
      );
    }
  }

  // Build group type selection chip
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
      selectedColor: Colors.purple,
      backgroundColor: Colors.grey.shade200,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      showCheckmark: false,
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
              // Group Image
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.purple.shade100,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : null,
                        child: _imageFile == null
                            ? const Icon(Icons.group, size: 50, color: Colors.purple)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.purple,
                          child: Icon(
                            _imageFile == null ? Icons.add_a_photo : Icons.edit,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Group Name TextField
              TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter group name',
                  filled: true,
                  fillColor: Colors.purple.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.purple.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.purple, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.group, color: Colors.purple),
                ),
              ),

              const SizedBox(height: 24),

              // Group Type Selection
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
                children: _groupTypes.map((type) => _buildGroupTypeButton(type)).toList(),
              ),

              const SizedBox(height: 24),

              // Members Section
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

              // Members List
              _buildMembersList()
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
                    // Check for duplicates
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