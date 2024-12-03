// activity_controller.dart

import 'package:get/get.dart';
import '../../../DatabaseHelper/hive_services.dart';
import '../../../modelClass/models.dart';
import '../services/activityPage_services.dart';

class ActivityController extends GetxController {
  final RxList<Activity> activities = <Activity>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadActivities();
  }

  Future<void> loadActivities() async {
    try {
      isLoading.value = true;
      activities.value = ActivityService.getAllActivities();
    } catch (e) {
      print('Error loading activities: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to group activities by date
  Map<DateTime, List<Activity>> get groupedActivities {
    final grouped = <DateTime, List<Activity>>{};

    for (var activity in activities) {
      final date = DateTime(
        activity.createdAt.year,
        activity.createdAt.month,
        activity.createdAt.day,
      );

      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(activity);
    }

    // Sort dates in descending order
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, grouped[key]!)),
    );
  }
}

class ActivityBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ActivityController());
  }
}