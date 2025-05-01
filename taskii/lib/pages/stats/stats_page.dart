import 'package:flutter/material.dart';
import '../../models/task.dart';

class StatsPage extends StatelessWidget {
  final List<Task> tasks;

  const StatsPage({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    // Calculate statistics
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = today.subtract(Duration(days: today.weekday - 1));
    final thisMonth = DateTime(today.year, today.month, 1);

    // Filter tasks for different time periods
    final todayTasks =
        tasks.where((task) {
          final taskDate = DateTime(
            task.dueDate.year,
            task.dueDate.month,
            task.dueDate.day,
          );
          return taskDate.isAtSameMomentAs(today);
        }).toList();

    final weekTasks =
        tasks.where((task) {
          final taskDate = DateTime(
            task.dueDate.year,
            task.dueDate.month,
            task.dueDate.day,
          );
          return taskDate.isAfter(thisWeek.subtract(const Duration(days: 1))) &&
              taskDate.isBefore(thisWeek.add(const Duration(days: 7)));
        }).toList();

    final monthTasks =
        tasks.where((task) {
          final taskDate = DateTime(
            task.dueDate.year,
            task.dueDate.month,
            task.dueDate.day,
          );
          return taskDate.isAfter(
                thisMonth.subtract(const Duration(days: 1)),
              ) &&
              taskDate.isBefore(DateTime(today.year, today.month + 1, 1));
        }).toList();

    // Calculate completion rates
    final todayCompletionRate =
        todayTasks.isEmpty
            ? 0.0
            : todayTasks.where((task) => task.isCompleted).length /
                todayTasks.length;
    final weekCompletionRate =
        weekTasks.isEmpty
            ? 0.0
            : weekTasks.where((task) => task.isCompleted).length /
                weekTasks.length;
    final monthCompletionRate =
        monthTasks.isEmpty
            ? 0.0
            : monthTasks.where((task) => task.isCompleted).length /
                monthTasks.length;

    // Calculate priority distribution
    final priorityCounts = {
      'High': tasks.where((task) => task.priority == 'High').length,
      'Medium': tasks.where((task) => task.priority == 'Medium').length,
      'Low': tasks.where((task) => task.priority == 'Low').length,
    };

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        shape: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 4,
          ),
        ),
        elevation: 4,
        title: const Text('Stats'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Completion Rates Section
            const Text(
              'Completion Rates',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCompletionCard(
              'Today',
              todayCompletionRate,
              todayTasks.length,
            ),
            const SizedBox(height: 8),
            _buildCompletionCard(
              'This Week',
              weekCompletionRate,
              weekTasks.length,
            ),
            const SizedBox(height: 8),
            _buildCompletionCard(
              'This Month',
              monthCompletionRate,
              monthTasks.length,
            ),
            const SizedBox(height: 24),

            // Priority Distribution Section
            const Text(
              'Priority Distribution',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPriorityCard(
              'High Priority',
              priorityCounts['High']!,
              tasks.length,
              Colors.red,
            ),
            const SizedBox(height: 8),
            _buildPriorityCard(
              'Medium Priority',
              priorityCounts['Medium']!,
              tasks.length,
              Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildPriorityCard(
              'Low Priority',
              priorityCounts['Low']!,
              tasks.length,
              Colors.green,
            ),
            const SizedBox(height: 24),

            // Task Overview Section
            const Text(
              'Task Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildOverviewCard(
              'Total Tasks',
              tasks.length.toString(),
              Icons.task,
            ),
            const SizedBox(height: 8),
            _buildOverviewCard(
              'Completed Tasks',
              tasks.where((task) => task.isCompleted).length.toString(),
              Icons.check_circle,
            ),
            const SizedBox(height: 8),
            _buildOverviewCard(
              'Pending Tasks',
              tasks.where((task) => !task.isCompleted).length.toString(),
              Icons.pending,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionCard(String period, double rate, int totalTasks) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              period,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: rate,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                rate >= 0.7
                    ? Colors.green
                    : rate >= 0.4
                    ? Colors.orange
                    : Colors.red,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${(rate * 100).toStringAsFixed(1)}% ($totalTasks tasks)',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityCard(
    String priority,
    int count,
    int total,
    Color color,
  ) {
    final percentage = total == 0 ? 0.0 : count / total;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              priority,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '$count tasks (${(percentage * 100).toStringAsFixed(1)}%)',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.black),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
