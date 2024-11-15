import 'dart:io';

import 'package:flutter/material.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';

class AddExpensePage extends StatefulWidget {
  final Expense? expense;
  final Group? group;
  const AddExpensePage({super.key, this.expense, this.group});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  List<Member> members = [];
  List<Member> selectedMembers = [];
  List<Group> groups = [];

  Group? selectedGroup;
  Member? selectedPayer;
  String selectedSplitOption = 'Equally';
  final Map<String, TextEditingController> _memberAmountControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchGroups();
    _initializeExpenseData();
  }

  @override
  void dispose() {
    _memberAmountControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _initializeExpenseData() {
    if (widget.expense != null) {
      List<Member> involvedMembers = [];

      widget.expense?.splits.forEach((sp){
        involvedMembers.add(sp.member);
      });
      _descriptionController.text = widget.expense!.description;
      _amountController.text = widget.expense!.totalAmount.toString();
      selectedGroup = widget.expense!.group;
      selectedPayer = widget.expense!.paidByMember;
      selectedMembers = involvedMembers.toList();
      selectedSplitOption = widget.expense!.divisionMethod == DivisionMethod.equal ? 'Equally' : 'By Amount';
      members = widget.expense!.group!.members;
      if (selectedSplitOption == 'By Amount') {
        _initializeMemberControllersWithCustomAmounts();
      }
    }
  }

  void _initializeMemberControllersWithCustomAmounts() {
    _memberAmountControllers.forEach((_, controller) => controller.dispose());
    _memberAmountControllers.clear();
    List<Member> involvedMembers = [];
    List<double> amounts = [];

    widget.expense?.splits.forEach((sp){
      involvedMembers.add(sp.member);
      amounts.add(sp.amount);
    });

    for (var i = 0; i <involvedMembers.length; i++) {
      var member =involvedMembers[i];
      _memberAmountControllers[member.name] = TextEditingController(
          text: amounts[i].toString() ?? '0.0'
      );
    }
  }
  void _initializeMemberControllers() {
    // Clear existing controllers
    _memberAmountControllers.forEach((_, controller) => controller.dispose());
    _memberAmountControllers.clear();

    // Create new controllers for each member
    for (var member in members) {
      _memberAmountControllers[member.name] = TextEditingController();
    }
  }
  Future<void> _fetchGroups() async {
    List<Group> fetchedGroups = await ExpenseManagerService.getAllGroups();
    setState(() {
      groups = fetchedGroups;
      if(widget.group!= null){
        selectedGroup = widget.group;
        members = selectedGroup!.members.toList();
        selectedPayer = null;
      }

    });
  }

  void _toggleMemberSelection(Member member) {
    setState(() {
      if (selectedMembers.contains(member)) {
        selectedMembers.remove(member);
      } else {
        selectedMembers.add(member);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Expense',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              if(_amountController.text.isEmpty) return;
              // if(selectedMembers.isEmpty) return;
              if(selectedGroup == null) return;
              if(selectedPayer == null) return;
              if(_descriptionController.text.isEmpty) return;

              if (selectedSplitOption == 'By Amount') {
                List<double> customAmounts = selectedMembers.map((member) {
                  return double.tryParse(_memberAmountControllers[member.name]?.text ?? '0') ?? 0.0;
                }).toList();

                if(widget.expense!=null){
                  ExpenseManagerService.updateExpense(
                      expense: widget.expense!,
                      totalAmount: double.tryParse(_amountController.text) ?? 0.0,
                      divisionMethod: DivisionMethod.unequal,
                      paidByMember: selectedPayer!,
                      involvedMembers: selectedMembers,
                      description: _descriptionController.text,
                    customAmounts: customAmounts,
                    group: selectedGroup,
                  );
                }else{
                  ExpenseManagerService.createExpense(
                      totalAmount: double.tryParse(_amountController.text) ?? 0.0,
                      divisionMethod:  DivisionMethod.unequal,
                      paidByMember: selectedPayer!,
                      involvedMembers: selectedMembers,
                      group: selectedGroup,
                      customAmounts:customAmounts,
                      description: _descriptionController.text
                  );
                }

              }else{
              if(widget.expense!=null){
                ExpenseManagerService.updateExpense(
                    totalAmount: double.tryParse(_amountController.text) ?? 0.0,
                    divisionMethod: DivisionMethod.equal,
                    paidByMember: selectedPayer!,
                    involvedMembers: selectedMembers,
                    group: selectedGroup,
                    description: _descriptionController.text,
                  expense: widget.expense!,
                );
              }else{
                ExpenseManagerService.createExpense(
                    totalAmount: double.tryParse(_amountController.text) ?? 0.0,
                    divisionMethod: DivisionMethod.equal,
                    paidByMember: selectedPayer!,
                    involvedMembers: selectedMembers,
                    group: selectedGroup,
                    description: _descriptionController.text
                );
              }
              }
              //Adding Expense

              Navigator.pop(context);
              // Add your save expense logic here
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Save'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.purple,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Group Selection Card
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Group',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Group>(
                      icon: const Icon(
                        Icons.expand_more_rounded, // Modern rounded arrow
                        size: 12,
                        color: Colors.purple, // Match your theme color
                      ),
                      isExpanded: true, // Add this to prevent overflow
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      value: selectedGroup,
                      hint: const Text("Choose a group"),
                      onChanged: (Group? newGroup) async {
                        setState(() {
                          selectedGroup = newGroup;
                          if (newGroup != null) {
                            members = newGroup.members.toList();
                            selectedPayer = null;
                          }
                        });
                      },
                      items: groups.map((Group group) {
                        return DropdownMenuItem<Group>(
                          value: group,
                          child: Wrap(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: FileImage(File(group.groupImage)),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    group.groupName,
                                    style: const TextStyle(fontSize: 12,fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    group.category ?? 'No category',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Expense Details Card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Field
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.currency_rupee,
                          size: 32,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const Divider(height: 32),
                    // Description Field
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'What was this expense for?',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.receipt_outlined,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Split Options Card
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Paid by',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<Member>(
                                icon: const Icon(
                                  Icons.expand_more_rounded, // Modern rounded arrow
                                  size: 12,
                                  color: Colors.purple, // Match your theme color
                                ),
                                padding: EdgeInsets.zero,
                                isExpanded: true, // Add this to prevent overflow
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                ),
                                value: selectedPayer,
                                hint: const Text("Select", style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis,),
                                onChanged: (value) => setState(() => selectedPayer = value),
                                items: (selectedGroup?.members ?? []).map((Member member) {
                                  return DropdownMenuItem<Member>(
                                    value: member,
                                    child: Text(member.name, overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Split',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                icon: const Icon(
                                  Icons.expand_more_rounded, // Modern rounded arrow
                                  size: 12,
                                  color: Colors.purple, // Match your theme color
                                ),
                                isExpanded: true, // Add this to prevent overflow
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                ),
                                value: selectedSplitOption,
                                onChanged: (value) {
                                  setState(() {
                                    selectedSplitOption = value!;
                                    if (value == 'By Amount') {
                                      _initializeMemberControllers();
                                    }
                                  });
                                },
                                items: ['Equally', 'By Amount'].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Members List
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final member = members[index];
                  final isSelected = selectedMembers.contains(member);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? Colors.purple[100] : Colors.grey[200],
                      child: Icon(
                        Icons.person_outline,
                        color: isSelected ? Colors.purple : Colors.grey[600],
                      ),
                    ),
                    title: Text(
                      member.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    trailing: selectedSplitOption == 'By Amount'
                        ? SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _memberAmountControllers[member.name],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: '0.00',
                          isDense: true,
                        ),
                      ),
                    )
                        : AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.purple : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? Colors.purple : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.check,
                        size: 20,
                        color: isSelected ? Colors.white : Colors.transparent,
                      ),
                    ),
                    onTap: () => _toggleMemberSelection(member),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}