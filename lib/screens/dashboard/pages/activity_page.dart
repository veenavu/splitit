// activity_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../DatabaseHelper/hive_services.dart';
import '../../../modelClass/models.dart';
import '../controller/activityPage_controller.dart';


class ActivitiesPage extends GetView<ActivityController> {
  const ActivitiesPage({super.key});

  // Get icon based on activity type
  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'group_created':
        return Icons.group_add;
      case 'group_name_changed':
        return Icons.edit;
      case 'group_type_changed':
        return Icons.category;
      case 'member_added':
        return Icons.person_add;
      case 'member_removed':
        return Icons.person_remove;
      case 'group_deleted':
        return Icons.delete_forever;
      case 'expense_added':
        return Icons.add_card;
      case 'expense_edited':
        return Icons.edit_note;
      case 'expense_deleted':
        return Icons.money_off;
      case 'settlement':
        return Icons.payments;
      default:
        return Icons.access_time;
    }
  }

  // Get color based on activity type
  Color _getActivityColor(String type) {
    switch (type) {
      case 'group_created':
        return Colors.green;
      case 'group_name_changed':
      case 'group_type_changed':
        return Colors.blue;
      case 'member_added':
        return Colors.purple;
      case 'member_removed':
        return Colors.orange;
      case 'group_deleted':
        return Colors.red;
      case 'expense_added':
        return Colors.teal;
      case 'expense_edited':
        return Colors.indigo;
      case 'expense_deleted':
        return Colors.deepOrange;
      case 'settlement':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.activities.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No recent activities',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadActivities(),
          child: ListView.builder(
            itemCount: controller.groupedActivities.length,
            itemBuilder: (context, index) {
              final date = controller.groupedActivities.keys.elementAt(index);
              final dayActivities = controller.groupedActivities[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateHeader(date),
                  ...dayActivities.map((activity) => _buildActivityCard(activity)),
                ],
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.purple.shade50,
      child: Text(
        DateFormat.yMMMMd().format(date),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.purple.shade700,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getActivityColor(activity.type).withOpacity(0.1),
          child: Icon(
            _getActivityIcon(activity.type),
            color: _getActivityColor(activity.type),
          ),
        ),
        title: Text(
          activity.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              activity.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat.jm().format(activity.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}