import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/dashboard/controller/dashboard_controller.dart';
import 'package:splitit/screens/dashboard/dashboard.dart';

class ExpenseController extends GetxController {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final Map<String, TextEditingController> _memberAmountControllers = {};

  final RxList<Member> members = <Member>[].obs;
  final RxList<Member> selectedMembers = <Member>[].obs;
  final RxList<Group> groups = <Group>[].obs;

  final Rxn<Group> selectedGroup = Rxn<Group>();
  final selectedPayer = Rx<Member?>(null);
  final RxString selectedSplitOption = 'Equally'.obs;

  RxDouble remaining = 0.0.obs;

  TextEditingController get descriptionController => _descriptionController;
  TextEditingController get amountController => _amountController;
  Map<String, TextEditingController> get memberAmountControllers => _memberAmountControllers;

  @override
  void onInit() {
    super.onInit();
    fetchGroups();
  }

  @override
  void onClose() {
    _descriptionController.dispose();
    _amountController.dispose();
    memberAmountControllers.forEach((_, controller) => controller.dispose());
    memberAmountControllers.clear();
    super.onClose();
  }


  void _resetData() {
    _descriptionController.text = '';
    _amountController.text = '';
    // _memberAmountControllers.forEach((_, controller) => controller.text = '');
    selectedPayer();
    selectedMembers.clear();
  }

  void initializeExpenseData(Expense? expense) {
    if (expense != null) {
      List<Member> involvedMembers = [];

      for (var sp in expense.splits) {
        involvedMembers.add(sp.member);
      }

      _descriptionController.text = expense.description;
      _amountController.text = expense.totalAmount.toString();
      selectedGroup.value = expense.group;
      selectedPayer.value = expense.paidByMember;
      selectedMembers.value = involvedMembers;
      selectedSplitOption.value = expense.divisionMethod == DivisionMethod.equal ? 'Equally' : 'By Amount';
      members.value = expense.group!.members;

      if (selectedSplitOption.value == 'By Amount') {
        initializeMemberControllersWithCustomAmounts(expense);
      }
    }else{
      _resetData();
    }
  }

  calculateRemaining(){
    double totalEntered = memberAmountControllers.values
        .map((c) => double.tryParse(c.text) ?? 0.0)
        .fold(0.0, (sum, amount) => sum + amount);

    double totalAmount = double.tryParse(amountController.text) ?? 0.0;
    remaining.value = totalAmount - totalEntered;

  }

  void initializeMemberControllersWithCustomAmounts(Expense expense) {
    // Clear existing controllers
    _memberAmountControllers.forEach((_, controller) {
      controller.removeListener(() {}); // Remove any existing listeners
      controller.dispose();
    });
    _memberAmountControllers.clear();

    // Clear selected members
    selectedMembers.clear();

    // Create controllers and add members with amounts
    for (var split in expense.splits) {
      final controller = TextEditingController(
          text: split.amount.toStringAsFixed(2)
      );

      // Add controller
      _memberAmountControllers[split.member.phone] = controller;

      // Add listener for automatic member selection
      controller.addListener(() {
        final amount = double.tryParse(controller.text) ?? 0.0;
        if (amount > 0) {
          if (!selectedMembers.contains(split.member)) {
            selectedMembers.add(split.member);
          }
        } else {
          selectedMembers.remove(split.member);
        }
      });

      // Add member to selected members since it has an amount
      if (split.amount > 0) {
        selectedMembers.add(split.member);
      }
    }
  }

// Optional: Helper method to initialize when editing an expense
  void initializeForEditing(Expense expense) {
    // Set split option based on division method
    selectedSplitOption.value = expense.divisionMethod == DivisionMethod.unequal
        ? 'By Amount'
        : 'Equal';

    // Initialize payer
    selectedPayer.value = expense.paidByMember;

    // Initialize amount controller
    _amountController.text = expense.totalAmount.toString();

    // Initialize description
    _descriptionController.text = expense.description;

    // Initialize member controllers with amounts
    initializeMemberControllersWithCustomAmounts(expense);
    // Set group if exists
    if (expense.group != null) {
      selectedGroup.value = expense.group;
    }
  }
  void initializeMemberAmountControllers() {
    _memberAmountControllers.forEach((_, controller) => controller.dispose());
    _memberAmountControllers.clear();

    for (var member in members) {
      _memberAmountControllers[member.phone] = TextEditingController();
    }
  }
  void fetchGroups() async {
    List<Group> fetchedGroups =  ExpenseManagerService.getAllGroups();
    groups.value = fetchedGroups;
  }
  void toggleMemberSelection(Member member) {
    if (selectedSplitOption.value == 'By Amount') {
      final controller = memberAmountControllers[member.phone];
      if (controller != null) {
        final amount = double.tryParse(controller.text) ?? 0.0;
        if (amount > 0) {
          if (!selectedMembers.contains(member)) {
            selectedMembers.add(member);
          }
        } else {
          selectedMembers.remove(member);
        }
      }
    } else {
      if (selectedMembers.contains(member)) {
        selectedMembers.remove(member);
      } else {
        selectedMembers.add(member);
      }
    }
  }
  void onGroupChanged(Group? newGroup) {
    selectedGroup.value = newGroup;
    if (newGroup != null) {
      members.value = newGroup.members.toList();

      for (var member in members) {
        toggleMemberSelection(member);
      }
      selectedPayer.value = null;
    }
  }
  void onSplitOptionChanged(String? value) {
    if (value != null) {
      selectedSplitOption.value = value;
      if (value == 'By Amount') {
        // Keep only members with amounts > 0
        selectedMembers.removeWhere((member) {
          final controller = memberAmountControllers[member.phone];
          final amount = double.tryParse(controller?.text ?? '') ?? 0.0;
          return amount <= 0;
        });

        for (var member in members) {
          _memberAmountControllers[member.phone] = TextEditingController();
        }
      }
    }
  }
  bool validateExpense() {
    return _amountController.text.isNotEmpty &&
        selectedGroup.value != null &&
        selectedPayer.value != null &&
        _descriptionController.text.isNotEmpty;
  }

  void saveExpense(Expense? existingExpense) async {
    if (!validateExpense()) return;

    try {
      final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
      final description = _descriptionController.text;

      // Common parameters for both create and update
      final params = {
        'totalAmount': totalAmount,
        'paidByMember': selectedPayer.value!,
        'involvedMembers': selectedMembers,
        'description': description,
        'group': selectedGroup.value,
      };

      if (selectedSplitOption.value == 'By Amount') {
        // Handle unequal split
        print("Selected Member Length: ${selectedMembers.length}");
        final customAmounts = selectedMembers.map((member) {
          // Use a unique identifier instead of name
          final controllerId = member.phone; // or member.key depending on your Member model
          final controller = _memberAmountControllers[controllerId];

          if (controller == null) {
            print('Warning: No controller found for member ${member.name} (${member.phone})');
            return 0.0;
          }

          final amount = double.tryParse(controller.text) ?? 0.0;
          print('Member: ${member.name}, Amount: $amount'); // Debug log
          return amount;
        }).toList();
        print('Total members: ${selectedMembers.length}');
        print('Total amounts: ${customAmounts.length}');
        print('Individual amounts: $customAmounts');

        // Validate total matches sum of splits
        final sumOfSplits = customAmounts.fold<double>(
            0, (sum, amount) => sum + amount
        );

        if ((sumOfSplits - totalAmount).abs() > 0.01) {
          Get.snackbar(
            'Error',
            'Sum of split amounts must equal total amount',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }

        if (existingExpense != null) {
          await ExpenseManagerService.updateExpense(
            expense: existingExpense,
            totalAmount: totalAmount,
            divisionMethod: DivisionMethod.unequal,
            paidByMember: selectedPayer.value!,
            involvedMembers: selectedMembers,
            customAmounts: customAmounts,
            description: description,
            group: selectedGroup.value,
          );
        } else {
          await ExpenseManagerService.createExpense(
            totalAmount: totalAmount,
            divisionMethod: DivisionMethod.unequal,
            paidByMember: selectedPayer.value!,
            involvedMembers: selectedMembers,
            customAmounts: customAmounts,
            description: description,
            group: selectedGroup.value,
          );
        }
      } else {
        // Handle equal split
        if (existingExpense != null) {
          await ExpenseManagerService.updateExpense(
            expense: existingExpense,
            totalAmount: totalAmount,
            divisionMethod: DivisionMethod.equal,
            paidByMember: selectedPayer.value!,
            involvedMembers: selectedMembers,
            description: description,
            group: selectedGroup.value,
          );
        } else {
          await ExpenseManagerService.createExpense(
            totalAmount: totalAmount,
            divisionMethod: DivisionMethod.equal,
            paidByMember: selectedPayer.value!,
            involvedMembers: selectedMembers,
            description: description,
            group: selectedGroup.value,
          );
        }
      }
      Get.back();
      Get.find<DashboardController>().getBalanceText();
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }}