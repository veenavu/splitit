// activity_service.dart

import 'package:hive/hive.dart';

import '../../../modelClass/models.dart';


class ActivityService {
  static const String activityBoxName = 'activities';

  // Log group creation
  static Future<void> logGroupCreated(Group group, Member creator) async {
    await _logActivity(
      type: 'group_created',
      title: 'New Group Created',
      description: '${creator.name} created group "${group.groupName}"',
      relatedGroup: group,
      relatedMember: creator,
    );
  }

  // Log group name change
  static Future<void> logGroupNameChanged(Group group, String oldName, String newName, Member editor) async {
    await _logActivity(
      type: 'group_name_changed',
      title: 'Group Name Changed',
      description: '${editor.name} changed group name from "$oldName" to "$newName"',
      relatedGroup: group,
      relatedMember: editor,
    );
  }

  // Log group type change
  static Future<void> logGroupTypeChanged(Group group, String? oldType, String? newType, Member editor) async {
    await _logActivity(
      type: 'group_type_changed',
      title: 'Group Type Changed',
      description: '${editor.name} changed group type from "${oldType ?? 'None'}" to "${newType ?? 'None'}"',
      relatedGroup: group,
      relatedMember: editor,
    );
  }

  // Log member added to group
  static Future<void> logMemberAdded(Group group, Member addedMember, Member adder) async {
    await _logActivity(
      type: 'member_added',
      title: 'Member Added to Group',
      description: '${adder.name} added ${addedMember.name} to group "${group.groupName}"',
      relatedGroup: group,
      relatedMember: addedMember,
    );
  }

  // Log member removed from group
  static Future<void> logMemberRemoved(Group group, Member removedMember, Member remover) async {
    await _logActivity(
      type: 'member_removed',
      title: 'Member Removed from Group',
      description: '${remover.name} removed ${removedMember.name} from group "${group.groupName}"',
      relatedGroup: group,
      relatedMember: removedMember,
    );
  }

  // Log group deleted
  static Future<void> logGroupDeleted(Group group, Member deleter) async {
    await _logActivity(
      type: 'group_deleted',
      title: 'Group Deleted',
      description: '${deleter.name} deleted group "${group.groupName}"',
      relatedMember: deleter,
    );
  }

  // Log expense added
  static Future<void> logExpenseAdded(Expense expense, Member creator) async {
    await _logActivity(
      type: 'expense_added',
      title: 'New Expense Added',
      description: '${creator.name} added expense "${expense.description}" of ₹${expense.totalAmount.toStringAsFixed(2)}' +
          (expense.group != null ? ' in group "${expense.group!.groupName}"' : ''),
      relatedGroup: expense.group,
      relatedMember: creator,
    );
  }

  // Log expense edited
  static Future<void> logExpenseEdited(Expense expense, Member editor, String changes) async {
    await _logActivity(
      type: 'expense_edited',
      title: 'Expense Edited',
      description: '${editor.name} edited expense "${expense.description}": $changes',
      relatedGroup: expense.group,
      relatedMember: editor,
    );
  }

  // Log expense deleted
  static Future<void> logExpenseDeleted(Expense expense, Member deleter) async {
    await _logActivity(
      type: 'expense_deleted',
      title: 'Expense Deleted',
      description: '${deleter.name} deleted expense "${expense.description}" of ₹${expense.totalAmount.toStringAsFixed(2)}',
      relatedGroup: expense.group,
      relatedMember: deleter,
    );
  }

  // Log settlement
  static Future<void> logSettlement(Member payer, Member receiver, double amount, List<Group>? groups) async {
    String groupInfo = '';
    if (groups != null && groups.isNotEmpty) {
      groupInfo = ' in ${groups.length == 1 ? 'group' : 'groups'} "${groups.map((g) => g.groupName).join(', ')}"';
    }

    await _logActivity(
      type: 'settlement',
      title: 'Settlement Made',
      description: '${payer.name} paid ₹${amount.toStringAsFixed(2)} to ${receiver.name}$groupInfo',
      relatedMember: payer,
    );
  }

  // Generic activity logging method
  static Future<void> _logActivity({
    required String type,
    required String title,
    required String description,
    Group? relatedGroup,
    Member? relatedMember,
  }) async {
    final box = Hive.box<Activity>(activityBoxName);

    final activity = Activity(
      type: type,
      title: title,
      description: description,
      relatedGroup: relatedGroup,
      relatedMember: relatedMember,
    );

    await box.add(activity);
  }

  // Get all activities
  static List<Activity> getAllActivities() {
    final box = Hive.box<Activity>(activityBoxName);
    return box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}