import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../modelClass/models.dart';
import '../controllers/staticstics_controller.dart';

class StatisticsPage extends GetView<StatisticsController> {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Financial Statistics',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () => controller.loadStatistics(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildTotalSpendCard(),
                const SizedBox(height: 20),
                _buildGroupsOwedPieChart(),
                const SizedBox(height: 20),
                _buildGroupsOwesPieChart(),
                const SizedBox(height: 20),
               // _buildCategorySpendingSection(),
              ],
            ),
          ),
        );
      }
      ),
    );
  }

  Widget _buildTotalSpendCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // Margin on both sides
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // Rounded corners
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Total Spending',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                controller.formatCurrency(controller.totalSpent.value),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildGroupsOwedPieChart() {
    if (controller.groupsOwedStats.isEmpty) {
      return const Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Groups that Owe You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text('No groups owe you money'),
              ),
            ],
          ),
        ),
      );
    }

    final totalOwed = controller.groupsOwedStats.fold(0.0, (sum, stat) => sum + (stat['amount'] as double));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Groups that Owe You',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: List.generate(
                    controller.groupsOwedStats.length,
                    (index) {
                      final stat = controller.groupsOwedStats[index];
                      final group = stat['group'] as Group;
                      final amount = stat['amount'] as double;
                      final percentage = (amount / totalOwed) * 100;

                      return PieChartSectionData(
                        color: Colors.primaries[index % Colors.primaries.length],
                        value: amount,
                        title: '${percentage.toStringAsFixed(1)}%',
                        radius: 50,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: controller.groupsOwedStats.asMap().entries.map((entry) {
                final index = entry.key;
                final stat = entry.value;
                final group = stat['group'] as Group;
                final amount = stat['amount'] as double;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.primaries[index % Colors.primaries.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(group.groupName),
                        ],
                      ),
                      Text(
                        controller.formatCurrency(amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsOwesPieChart() {
    if (controller.groupsOwesStats.isEmpty) {
      return const Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Groups You Owe',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text('You don\'t owe any groups'),
              ),
            ],
          ),
        ),
      );
    }

    final totalOwes = controller.groupsOwesStats.fold(0.0, (sum, stat) => sum + (stat['amount'] as double));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Groups You Owe',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: List.generate(
                    controller.groupsOwesStats.length,
                    (index) {
                      final stat = controller.groupsOwesStats[index];
                      final group = stat['group'] as Group;
                      final amount = stat['amount'] as double;
                      final percentage = (amount / totalOwes) * 100;

                      return PieChartSectionData(
                        color: Colors.primaries[index % Colors.primaries.length].withOpacity(0.8),
                        value: amount,
                        title: '${percentage.toStringAsFixed(1)}%',
                        radius: 50,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: controller.groupsOwesStats.asMap().entries.map((entry) {
                final index = entry.key;
                final stat = entry.value;
                final group = stat['group'] as Group;
                final amount = stat['amount'] as double;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.primaries[index % Colors.primaries.length].withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(group.groupName),
                        ],
                      ),
                      Text(
                        controller.formatCurrency(amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

}
