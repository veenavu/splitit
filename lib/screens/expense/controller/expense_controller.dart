import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/dashboard/controller/dashboard_controller.dart';

import '../../dashboard/controller/friendsPage_controller.dart';

class ExpenseController extends GetxController {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  final Map<String, TextEditingController> _memberAmountControllers = {};

  final RxList<Member> members = <Member>[].obs;
  final RxList<Member> selectedMembers = <Member>[].obs;
  final RxList<Group> groups = <Group>[].obs;

  final Rxn<Group> selectedGroup = Rxn<Group>();
  final selectedPayer = Rx<Member?>(null);
  final RxString selectedSplitOption = 'Equally'.obs;

  late Expense selectedExpense;
  RxDouble remaining = 0.0.obs;

  TextEditingController get descriptionController => _descriptionController;
  TextEditingController get amountController => _amountController;
  Map<String, TextEditingController> get memberAmountControllers => _memberAmountControllers;



  //
  // final _descriptionController = TextEditingController();
  // final _amountController = TextEditingController();
  // final Map<String, TextEditingController> _memberAmountControllers = {};
  //
  // final RxList<Member> members = <Member>[].obs;
  // final RxList<Member> selectedMembers = <Member>[].obs;
  // final RxList<Group> groups = <Group>[].obs;
  //
  // final Rxn<Group> selectedGroup = Rxn<Group>();
  // final selectedPayer = Rx<Member?>(null);
  // final RxString selectedSplitOption = 'Equally'.obs;
  //
  // late Expense selectedExpense;

  onExpenseSelected(Expense expense) {
    selectedExpense = expense;
    print(selectedExpense.description);
  }

  // RxDouble remaining = 0.0.obs;
  //
  // TextEditingController get descriptionController => _descriptionController;
  //
  // TextEditingController get amountController => _amountController;
  //
  // Map<String, TextEditingController> get memberAmountControllers => _memberAmountControllers;

  void initializeExpenseData(Expense? expense) {
    // Clear previous data first
    _resetData();

    if (expense != null) {
      _descriptionController.text = expense.description;
      _amountController.text = expense.totalAmount.toString();
      selectedGroup.value = expense.group;
      selectedPayer.value = expense.paidByMember;

      selectedSplitOption.value = expense.divisionMethod == DivisionMethod.equal ? 'Equally' : 'By Amount';

      if (expense.group != null) {
        members.value = expense.group!.members;
      }

      selectedMembers.value = expense.splits.map((split) => split.member).toList();

      if (expense.divisionMethod == DivisionMethod.unequal) {
        _memberAmountControllers.clear();
        for (var split in expense.splits) {
          _memberAmountControllers[split.member.phone] = TextEditingController(text: split.amount.toStringAsFixed(2));
        }

        for (var member in members) {
          if (!_memberAmountControllers.containsKey(member.phone)) {
            _memberAmountControllers[member.phone] = TextEditingController(text: '0.00');
          }
        }

        calculateRemaining();
      }
    }
  }

  Future<void> saveExpense(Expense? existingExpense) async {
    if (!validateExpense()) {
      Get.snackbar(
        'Error',
        'Please fill all required fields',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
      final description = _descriptionController.text;

      if (selectedSplitOption.value == 'By Amount') {
        // Handle unequal split
        final customAmounts = selectedMembers.map((member) {
          final controller = _memberAmountControllers[member.phone];
          if (controller == null) {
            throw Exception('No amount controller found for member ${member.name}');
          }
          return double.tryParse(controller.text) ?? 0.0;
        }).toList();

        // Validate total matches sum of splits
        final sumOfSplits = customAmounts.reduce((a, b) => a + b);
        if ((sumOfSplits - totalAmount).abs() > 0.01) {
          Get.snackbar(
            'Error',
            'Sum of split amounts (${sumOfSplits.toStringAsFixed(2)}) must equal total amount (${totalAmount.toStringAsFixed(2)})',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }

        if (existingExpense != null) {
          selectedExpense = existingExpense;
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
          selectedExpense = existingExpense;
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
      // In your expense controller after saving/updating/deleting an expense
      Get.put(FriendsController()).loadMembers();

// In your settlement controller after completing a settlement
      Get.find<FriendsController>().loadMembers();

      // Refresh the dashboard after saving
      Get.find<DashboardController>().getBalanceText();
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save expense: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
  }

  bool validateExpense() {
    if (_amountController.text.isEmpty || double.tryParse(_amountController.text) == null) {
      return false;
    }
    if (_descriptionController.text.isEmpty) {
      return false;
    }
    if (selectedPayer.value == null) {
      return false;
    }
    if (selectedMembers.isEmpty) {
      return false;
    }

    return true;
  }


  @override
  void onInit() {
    super.onInit();
    // Initialize controllers in onInit
    _descriptionController = TextEditingController();
    _amountController = TextEditingController();
    fetchGroups();
  }

  @override
  void onClose() {
    // Clean up controllers in onClose
    _descriptionController.dispose();
    _amountController.dispose();
    _memberAmountControllers.forEach((_, controller) => controller.dispose());
    _memberAmountControllers.clear();
    super.onClose();
  }
  void _resetData() {
    _descriptionController.text = '';
    _amountController.text = '';
    _memberAmountControllers.forEach((_, controller) => controller.dispose());
    _memberAmountControllers.clear();
    selectedPayer.value = null;
    selectedMembers.clear();
    remaining.value = 0.0;
  }

  calculateRemaining() {
    double totalEntered = memberAmountControllers.values.map((c) => double.tryParse(c.text) ?? 0.0).fold(0.0, (sum, amount) => sum + amount);

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
      final controller = TextEditingController(text: split.amount.toStringAsFixed(2));

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
    selectedSplitOption.value = expense.divisionMethod == DivisionMethod.unequal ? 'By Amount' : 'Equal';

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
    List<Group> fetchedGroups = ExpenseManagerService.getAllGroups();
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
}
