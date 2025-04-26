import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/task.dart';
import '../services/task_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'pages/tasks/tasks_page.dart';
import 'pages/add_task/add_task_page.dart';
import 'pages/calendar/calendar_page.dart';
import 'pages/stats/stats_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPageIndex = 0;
  final TaskService _taskService = TaskService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _subscription;

  // Calendar related variables
  final DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    FirebaseDatabase.instance.goOnline();
    _isLoading = true; // Only here!
    _loadTasks();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadTasks() async {
    await _subscription?.cancel();
    _subscription = _taskService.getUserTasks(_auth.currentUser?.uid ?? '')
        .listen(
          (tasks) {
            if (mounted) {
              setState(() {
                _tasks = tasks;
                _isLoading = false;
                _generateEvents();
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _errorMessage = error.toString();
                _isLoading = false;
              });
            }
          },
        );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _generateEvents() {
    Map<DateTime, List<Map<String, dynamic>>> tempEvents = {};

    for (var task in _tasks) {
      // Normalize the date to remove time component
      DateTime date = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);

      if (!tempEvents.containsKey(date)) {
        tempEvents[date] = [];
      }
      
      Map<String, dynamic> taskMap = {
        'title': task.title,
        'description': task.description,
        'priority': task.priority,
        'dueDate': task.dueDate,
        'id': task.id,
        'isCompleted': task.isCompleted,
        'userId': task.userId,
      };
      tempEvents[date]!.add(taskMap);
    }
    
    setState(() {
      _events = tempEvents;
    });
  }

  List<Map<String, dynamic>> _getTasksForDay(DateTime day) {
    // Normalize the date to remove time component
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  // Helper methods for task management
  Task? _getCurrentTask() {
    if (_tasks.isEmpty) return null;
    final now = DateTime.now();
    // Only consider incomplete tasks that are due after now
    return _tasks.where((task) => !task.isCompleted && task.dueDate.isAfter(now))
      .fold<Task?>(null, (currentMin, task) {
        if (currentMin == null) return task;
        return task.dueDate.isBefore(currentMin.dueDate) ? task : currentMin;
      });
  }

  String _getTimeLeft() {
    final currentTask = _getCurrentTask();
    if (currentTask == null) return '0min left';

    final now = DateTime.now();
    final difference = currentTask.dueDate.difference(now);

    if (difference.isNegative) return 'Overdue';
    if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes.remainder(60)}min left';
    }
    return '${difference.inMinutes}min left till start ';
  }

  Task? _getNextHighPriorityTask() {
    final now = DateTime.now();
    try {
      return _tasks.firstWhere(
        (task) =>
          task.priority == 'High' &&
          task.dueDate.isAfter(now) &&
          task.dueDate.difference(now).inMinutes <= 30,
      );
    } catch (e) {
      return null;
    }
  }

  List<Task> _getUpcomingTasks() {
    final now = DateTime.now();
    return _tasks
        .where((task) => task.dueDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<Map<String, dynamic>> _getFreeTimeSlots() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    // Get all tasks for today
    final todayTasks = _tasks.where((task) {
      final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      return taskDate.isAtSameMomentAs(today);
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    List<Map<String, dynamic>> freeSlots = [];

    // If no tasks, the whole day is free
    if (todayTasks.isEmpty) {
      freeSlots.add({
        'start': now,
        'end': tomorrow,
        'duration': 'All day'
      });
      return freeSlots;
    }

    // Check time before first task
    if (todayTasks.first.dueDate.isAfter(now)) {
      freeSlots.add({
        'start': now,
        'end': todayTasks.first.dueDate,
        'duration': _formatDuration(todayTasks.first.dueDate.difference(now))
      });
    }

    // Check time between tasks
    for (int i = 0; i < todayTasks.length - 1; i++) {
      final currentTask = todayTasks[i];
      final nextTask = todayTasks[i + 1];

      // Only add free time slots that start after the current time
      if (nextTask.dueDate.difference(currentTask.dueDate) > const Duration(minutes: 30) &&
          currentTask.dueDate.isAfter(now)) {
        freeSlots.add({
          'start': currentTask.dueDate,
          'end': nextTask.dueDate,
          'duration': _formatDuration(nextTask.dueDate.difference(currentTask.dueDate))
        });
      }
    }

    // Check time after last task
    final lastTask = todayTasks.last;
    if (lastTask.dueDate.isBefore(tomorrow) && lastTask.dueDate.isAfter(now)) {
      freeSlots.add({
        'start': lastTask.dueDate,
        'end': tomorrow,
        'duration': _formatDuration(tomorrow.difference(lastTask.dueDate))
      });
    }

    return freeSlots;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} ${minutes > 0 ? '$minutes min' : ''}';
    }
    return '$minutes min';
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  // Add this method to calculate day progress
  double _calculateDayProgress() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get all tasks for today
    final todayTasks = _tasks.where((task) {
      final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      return taskDate.isAtSameMomentAs(today);
    }).toList();

    if (todayTasks.isEmpty) return 0.0;

    // Count completed tasks for today
    final completedTasks = todayTasks.where((task) => task.isCompleted).length;

    // Calculate progress as a percentage (0.0 to 1.0)
    return completedTasks / todayTasks.length;
  }

  Future<void> _refreshHome() async {
    await _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                setState(() {
                  _errorMessage = null;
                });
              },
            ),
          ),
        );
      });
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: currentPageIndex == 0
          ? AppBar(
              title: const Text('Home'),
              shape: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 4,
                ),
              ),
              elevation: 4,
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Settings',
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
              ],
            )
          : null, // No AppBar for other pages
      body: IndexedStack(
        index: currentPageIndex,
        children: [
          // Home page content as a scrollable widget (NOT a Scaffold)
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshHome,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 280.0), // <-- Add bottom padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day Progress Section
                      Builder(
                        builder: (context) {
                          // Get all tasks for today
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final todayTasks = _tasks.where((task) {
                            final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
                            return taskDate.isAtSameMomentAs(today);
                          }).toList();

                          if (todayTasks.isEmpty) {
                            return const SizedBox.shrink(); // Hide progress bar and percentage
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Day Progress',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${(_calculateDayProgress() * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _calculateDayProgress(),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                  backgroundColor: Colors.grey[300],
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Current Task Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current/Upcoming Task',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getCurrentTask()?.title ?? 'No current task',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getTimeLeft(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // High Priority Warning
                      if (_getNextHighPriorityTask() != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_rounded,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'High priority task "${_getNextHighPriorityTask()?.title}" ${_getTimeLeftForHighPriorityTask()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Up Next Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Up Next',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._getUpcomingTasks().map((task) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.only(left: 0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      decoration: BoxDecoration(
                                        color: _getPriorityColor(task.priority),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(7),
                                          bottomLeft: Radius.circular(7),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: task.isCompleted,
                                              onChanged: (bool? value) {
                                                _toggleTaskCompletion(task);
                                              },
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    task.title,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                      decoration: task.isCompleted 
                                                        ? TextDecoration.lineThrough 
                                                        : TextDecoration.none,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    DateFormat('h:mm a').format(task.dueDate),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )),
                        ],
                      ),

                      // Available Free Time Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Free Time',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._getFreeTimeSlots().map((slot) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('h:mm a').format(slot['start']),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('h:mm a').format(slot['end']),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    slot['duration'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Navigate to add task page with pre-filled time
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AddTaskPage(
                                              initialDate: slot['start'],
                                              initialTime: TimeOfDay.fromDateTime(slot['start']),
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Schedule Task',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          TasksPage(
            tasks: _tasks,
            onTaskCompletion: _toggleTaskCompletion,
            onTaskDelete: _deleteTask,
            onFilterApply: _applyFilters,
            onFilterClear: _clearFilters,
          ),
          AddTaskPage(),
          CalendarPage(
            tasks: _tasks,
            onTaskCompletion: _toggleTaskCompletion,
            onTaskDelete: _deleteTask,
            onFilterApply: _applyFilters,
            onFilterClear: _clearFilters,
            onRefresh: _refreshHome, // <-- Add this line
          ),
          StatsPage(
            tasks: _tasks,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Theme.of(context).colorScheme.primary,
        indicatorShape: CircleBorder(),
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home), 
            label: 'Home',
            tooltip: "",
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_rounded),
            label: 'Tasks',
            tooltip: "",
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle, size: 60),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
            tooltip: "",
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Stats',
            tooltip: "",
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An error occurred',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTasks,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Add this method to mark a task as completed
  Future<void> _toggleTaskCompletion(Task task) async {
    try {
      final updatedTask = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        dueDate: task.dueDate,
        priority: task.priority,
        category: task.category,
        isCompleted: !task.isCompleted,
        userId: task.userId,
      );
      
      await _taskService.updateTask(updatedTask);
      
      // Force a UI update by refreshing the state
      setState(() {
        // Update the task in the local list
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = updatedTask;
        }

        // If this was the current task and it's now completed,
        // the UI will automatically update to show the next task
        // since _getCurrentTask() filters out completed tasks
      });

      _showSuccessSnackBar('Task ${task.isCompleted ? "uncompleted" : "completed"}!');
    } catch (e) {
      _showSnackBar('Failed to update task: ${e.toString()}');
    }
  }

  // Add this method to delete a task
  Future<void> _deleteTask(Task task) async {
    try {
      await _taskService.deleteTask(task.id);
      _showSuccessSnackBar('Task deleted successfully!');
    } catch (e) {
      _showSnackBar('Failed to delete task: ${e.toString()}');
    }
  }

  // Add this method to show the filter dialog
  void _showFilterDialog(BuildContext context) {
    // Use the stored filter values
    String selectedPriority = 'All';
    bool showCompleted = true;
    bool showIncomplete = true;
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Tasks'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Priority Filter
                    DropdownButtonFormField<String>(
                      value: selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: ['All', 'High', 'Medium', 'Low']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedPriority = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Completion Status Filter
                    const Text('Show Tasks:'),
                    CheckboxListTile(
                      title: const Text('Completed'),
                      value: showCompleted,
                      onChanged: (bool? value) {
                        setState(() {
                          showCompleted = value!;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Incomplete'),
                      value: showIncomplete,
                      onChanged: (bool? value) {
                        setState(() {
                          showIncomplete = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Range Filter
                    const Text('Date Range:'),
                    ListTile(
                      title: Text(startDate == null
                          ? 'Select Start Date'
                          : DateFormat('yyyy-MM-dd').format(startDate!)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            startDate = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: Text(endDate == null
                          ? 'Select End Date'
                          : DateFormat('yyyy-MM-dd').format(endDate!)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            endDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Clear all filters
                    _clearFilters();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Clear Filters'),
                ),
                TextButton(
                  onPressed: () {
                    // Apply filters
                    _applyFilters(
                      selectedPriority,
                      showCompleted,
                      showIncomplete,
                      startDate,
                      endDate,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Add this method to apply the filters
  void _applyFilters(
    String priority,
    bool showCompleted,
    bool showIncomplete,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    // If all filters are at their default values, reset filtered tasks
    if (priority == 'All' && showCompleted && showIncomplete && startDate == null && endDate == null) {
      setState(() {
        _tasks = List.from(_tasks);
      });
      return;
    }

    // Apply filters to a copy of all tasks
    setState(() {
      _tasks = _tasks.where((task) {
        // Priority filter
        if (priority != 'All' && task.priority != priority) {
          return false;
        }

        // Completion status filter
        if (!showCompleted && task.isCompleted) {
          return false;
        }
        if (!showIncomplete && !task.isCompleted) {
          return false;
        }

        // Date range filter
        if (startDate != null && task.dueDate.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && task.dueDate.isAfter(endDate)) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  // Add this method to clear all filters
  void _clearFilters() {
    setState(() {
      _tasks = List.from(_tasks); // Reset filtered tasks to show all tasks
    });
  }

  // Add this method to calculate time left for high priority task
  String _getTimeLeftForHighPriorityTask() {
    final task = _getNextHighPriorityTask();
    if (task == null) return '';

    final now = DateTime.now();
    final difference = task.dueDate.difference(now);

    if (difference.isNegative) return 'starts now';
    if (difference.inMinutes < 1) return 'starts in less than a minute';
    return 'starts in ${difference.inMinutes} minutes';
  }
}
