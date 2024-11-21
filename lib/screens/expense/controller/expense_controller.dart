import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';

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
    _memberAmountControllers.forEach((_, controller) => controller.dispose());
    super.onClose();
  }


  void _resetData() {
    _descriptionController.text = '';
    _amountController.text = '';
    _memberAmountControllers.forEach((_, controller) => controller.text = '');
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

  void initializeMemberControllersWithCustomAmounts(Expense expense) {
    _memberAmountControllers.forEach((_, controller) => controller.dispose());
    _memberAmountControllers.clear();

    List<Member> involvedMembers = [];
    List<double> amounts = [];

    for (var sp in expense.splits) {
      involvedMembers.add(sp.member);
      amounts.add(sp.amount);
    }

    for (var i = 0; i < involvedMembers.length; i++) {
      var member = involvedMembers[i];
      _memberAmountControllers[member.name] = TextEditingController(
        text: amounts[i].toString(),
      );
    }
  }

  void initializeMemberAmountControllers() {
    _memberAmountControllers.forEach((_, controller) => controller.dispose());
    _memberAmountControllers.clear();

    for (var member in members) {
      _memberAmountControllers[member.name] = TextEditingController();
    }
  }

  void fetchGroups() async {
    List<Group> fetchedGroups =  ExpenseManagerService.getAllGroups();
    groups.value = fetchedGroups;
  }

  void toggleMemberSelection(Member member) {
    if (selectedMembers.contains(member)) {
      selectedMembers.remove(member);
    } else {
      selectedMembers.add(member);
    }
    update();
  }

  void onGroupChanged(Group? newGroup) {
    selectedGroup.value = newGroup;
    if (newGroup != null) {
      members.value = newGroup.members.toList();
      selectedPayer.value = null;
    }
  }

  void onSplitOptionChanged(String? value) {
    if (value != null) {
      selectedSplitOption.value = value;
      if (value == 'By Amount') {
        initializeMemberAmountControllers();
      }
    }
  }

  bool validateExpense() {
    return _amountController.text.isNotEmpty &&
        selectedGroup.value != null &&
        selectedPayer.value != null &&
        _descriptionController.text.isNotEmpty;
  }

  void saveExpense(Expense? existingExpense) {
    if (!validateExpense()) return;

    if (selectedSplitOption.value == 'By Amount') {
      List<double> customAmounts = selectedMembers.map((member) {
        return double.tryParse(_memberAmountControllers[member.name]?.text ?? '0') ?? 0.0;
      }).toList();

      if (existingExpense != null) {
        ExpenseManagerService.updateExpense(
          expense: existingExpense,
          totalAmount: double.tryParse(_amountController.text) ?? 0.0,
          divisionMethod: DivisionMethod.unequal,
          paidByMember: selectedPayer.value!,
          involvedMembers: selectedMembers,
          description: _descriptionController.text,
          customAmounts: customAmounts,
          group: selectedGroup.value,
        );
      } else {
        ExpenseManagerService.createExpense(
          totalAmount: double.tryParse(_amountController.text) ?? 0.0,
          divisionMethod: DivisionMethod.unequal,
          paidByMember: selectedPayer.value!,
          involvedMembers: selectedMembers,
          group: selectedGroup.value,
          customAmounts: customAmounts,
          description: _descriptionController.text,
        );
      }
    } else {
      if (existingExpense != null) {
        ExpenseManagerService.updateExpense(
          totalAmount: double.tryParse(_amountController.text) ?? 0.0,
          divisionMethod: DivisionMethod.equal,
          paidByMember: selectedPayer.value!,
          involvedMembers: selectedMembers,
          group: selectedGroup.value,
          description: _descriptionController.text,
          expense: existingExpense,
        );
      } else {
        ExpenseManagerService.createExpense(
          totalAmount: double.tryParse(_amountController.text) ?? 0.0,
          divisionMethod: DivisionMethod.equal,
          paidByMember: selectedPayer.value!,
          involvedMembers: selectedMembers,
          group: selectedGroup.value,
          description: _descriptionController.text,
        );
      }
    }
    Get.back();
  }
}