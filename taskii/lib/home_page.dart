import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/task.dart';
import '../services/task_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'pages/tasks/tasks_page.dart';
import 'pages/calendar/calendar_page.dart';
import 'pages/stats/stats_page.dart';
import 'pages/add_task/add_task_page.dart';

class TimeSlot {
  final DateTime start;
  final DateTime end;
  final Duration duration;

  TimeSlot({required this.start, required this.end})
      : duration = end.difference(start);

  String formattedStartTime(BuildContext context) {
    return _formatTimeHelper(start);
  }

  String formattedEndTime(BuildContext context) {
    return _formatTimeHelper(end);
  }

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours > 0 ? "$hours hour${hours != 1 ? 's' : ''} " : ""}${minutes > 0 ? "$minutes min" : ""}';
  }

  static String _formatTimeHelper(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

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

  @override
  void initState() {
    super.initState();
    FirebaseDatabase.instance.goOnline();
    _isLoading = true;
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
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? _buildLoadingIndicator()
          : _errorMessage != null
              ? _buildErrorWidget()
              : IndexedStack(
                  index: currentPageIndex,
                  children: [
                    Scaffold(
                      appBar: AppBar(
                        shape: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 4,
                          ),
                        ),
                        elevation: 4,
                        centerTitle: false,
                        title: const Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        actions: [
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
                            // Day Progress Section
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Day Progress',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${(_tasks.where((task) => task.isCompleted).length / _tasks.length * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: _tasks.isEmpty ? 0 : _tasks.where((task) => task.isCompleted).length / _tasks.length,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Current/Upcoming Task Section
                            const Text(
                              'Current Task',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Card(
                              child: _buildCurrentTask(),
                            ),
                            const SizedBox(height: 24),
                            // Up Next Section
                            const Text(
                              'Up Next',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              children: _buildUpcomingTasks(),
                            ),
                            const SizedBox(height: 24),
                            // Available Free Time Section
                            const Text(
                              'Available Free Time',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildAvailableFreeTime(),
                          ],
                        ),
                      ),
                    ),
                    TasksPage(
                      tasks: _tasks,
                      onTaskCompletion: (task) async {
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
                            estimatedTime: task.estimatedTime,
                          );
                          await _taskService.updateTask(updatedTask);
                          _showSnackBar('Task ${task.isCompleted ? "uncompleted" : "completed"}!', isError: false);
                        } catch (e) {
                          _showSnackBar('Failed to update task: ${e.toString()}');
                        }
                      },
                      onTaskDelete: (task) async {
                        try {
                          await _taskService.deleteTask(task.id);
                          _showSnackBar('Task deleted successfully!', isError: false);
                        } catch (e) {
                          _showSnackBar('Failed to delete task: ${e.toString()}');
                        }
                      },
                      onFilterApply: (priority, showCompleted, showIncomplete, startDate, endDate) {
                        setState(() {
                          _tasks = _tasks.where((task) {
                            if (priority != 'All' && task.priority != priority) {
                              return false;
                            }
                            if (!showCompleted && task.isCompleted) {
                              return false;
                            }
                            if (!showIncomplete && !task.isCompleted) {
                              return false;
                            }
                            if (startDate != null && task.dueDate.isBefore(startDate)) {
                              return false;
                            }
                            if (endDate != null && task.dueDate.isAfter(endDate)) {
                              return false;
                            }
                            return true;
                          }).toList();
                        });
                      },
                      onFilterClear: () {
                        _loadTasks();
                      },
                    ),
                    CalendarPage(
                      tasks: _tasks,
                      onTaskCompletion: (task) async {
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
                            estimatedTime: task.estimatedTime,
                          );
                          await _taskService.updateTask(updatedTask);
                          _showSnackBar('Task ${task.isCompleted ? "uncompleted" : "completed"}!', isError: false);
                        } catch (e) {
                          _showSnackBar('Failed to update task: ${e.toString()}');
                        }
                      },
                      onTaskDelete: (task) async {
                        try {
                          await _taskService.deleteTask(task.id);
                          _showSnackBar('Task deleted successfully!', isError: false);
                        } catch (e) {
                          _showSnackBar('Failed to delete task: ${e.toString()}');
                        }
                      },
                      onFilterApply: (priority, showCompleted, showIncomplete, startDate, endDate) {
                        setState(() {
                          _tasks = _tasks.where((task) {
                            if (priority != 'All' && task.priority != priority) {
                              return false;
                            }
                            if (!showCompleted && task.isCompleted) {
                              return false;
                            }
                            if (!showIncomplete && !task.isCompleted) {
                              return false;
                            }
                            if (startDate != null && task.dueDate.isBefore(startDate)) {
                              return false;
                            }
                            if (endDate != null && task.dueDate.isAfter(endDate)) {
                              return false;
                            }
                            return true;
                          }).toList();
                        });
                      },
                      onFilterClear: () {
                        _loadTasks();
                      },
                      onRefresh: _loadTasks,
                    ),
                    StatsPage(tasks: _tasks),
                  ],
                ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          if (index == 2) { // Add Task button is now at index 2
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddTaskPage(
                  onExit: _loadTasks,
                ),
              ),
            );
          } else {
            setState(() {
              currentPageIndex = index > 2 ? index - 1 : index; // Adjust index for other destinations
            });
          }
        },
        selectedIndex: currentPageIndex < 2 ? currentPageIndex : currentPageIndex + 1,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.task),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.add, size: 44),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTask() {
    final currentTask = _getCurrentTask();
    if (currentTask == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No current tasks'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentTask.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getTimeLeft(currentTask),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildUpcomingTasks() {
    final upcomingTasks = _getUpcomingTasks();
    if (upcomingTasks.isEmpty) {
      return [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No upcoming tasks'),
          ),
        ),
      ];
    }

    return upcomingTasks.map((task) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(task.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.priority,
                    style: TextStyle(
                      color: _getPriorityColor(task.priority),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              _formatTime(task.dueDate),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    )).toList();
  }

  List<Task> _getUpcomingTasks() {
    final now = DateTime.now();
    
    // Get all incomplete tasks that haven't finished their time window
    final futureTasks = _tasks
        .where((task) {
          if (task.isCompleted) return false;
          
          // Calculate task's time window end
          final taskEndTime = task.dueDate.add(Duration(minutes: task.estimatedTime));
          
          // Only include tasks that haven't finished their time window
          return now.isBefore(taskEndTime);
        })
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // If we have no tasks, return empty list
    if (futureTasks.isEmpty) {
      return [];
    }

    // Get the current task
    final currentTask = _getCurrentTask();
    if (currentTask != null) {
      // Remove the current task from upcoming tasks
      final currentTaskIndex = futureTasks.indexWhere((task) => task.id == currentTask.id);
      if (currentTaskIndex != -1) {
        // Return up to 3 tasks after the current task
        return futureTasks
            .sublist(currentTaskIndex + 1)
            .take(3)
            .toList();
      }
    }

    // If no current task is being displayed, show the next 3 tasks
    return futureTasks.take(3).toList();
  }

  Task? _getCurrentTask() {
    final now = DateTime.now();
    
    // Get all incomplete tasks that are either:
    // 1. Currently in their time window (started but not finished)
    // 2. Next to start (future tasks)
    final eligibleTasks = _tasks
        .where((task) {
          if (task.isCompleted) return false;
          
          // Calculate task's time window
          final taskStartTime = task.dueDate;
          final taskEndTime = task.dueDate.add(Duration(minutes: task.estimatedTime));
          
          // Task is currently in its time window
          if (now.isAfter(taskStartTime) && now.isBefore(taskEndTime)) {
            return true;
          }
          
          // Task hasn't started yet
          if (now.isBefore(taskStartTime)) {
            return true;
          }
          
          return false;
        })
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // If we have tasks, return the earliest one
    // This will be either:
    // - The earliest task currently in its time window
    // - The next task to start if no tasks are currently in their window
    return eligibleTasks.isEmpty ? null : eligibleTasks.first;
  }

  String _getTimeLeft(Task task) {
    final now = DateTime.now();
    
    // Check if task is in progress (within its time window)
    if (now.isAfter(task.dueDate)) {
      final taskEndTime = task.dueDate.add(Duration(minutes: task.estimatedTime));
      if (now.isBefore(taskEndTime)) {
        return 'In Progress';
      }
    }
    
    // If not in progress, show time until start
    final difference = task.dueDate.difference(now);
    if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}min left';
    }
    return '${difference.inMinutes}min till start';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAvailableFreeTime() {
    final now = DateTime.now();
    if (now.hour >= 23 && now.minute >= 59) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No more free time available today'),
        ),
      );
    }

    final List<TimeSlot> availableSlots = _getAvailableTimeSlots();
    
    if (availableSlots.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No available free time slots today'),
        ),
      );
    }

    return Column(
      children: [
        // Add a helper text to explain the free time slots
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Free time slots are calculated based on incomplete tasks only',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        ...availableSlots.map((TimeSlot slot) => Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      slot.formattedStartTime(context),
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(
                      slot.formattedEndTime(context),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  slot.formattedDuration,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTaskPage(
                            initialDate: slot.start,
                            initialTime: TimeOfDay(hour: slot.start.hour, minute: slot.start.minute),
                            onExit: _loadTasks,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Schedule Task',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }

  List<TimeSlot> _getAvailableTimeSlots() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);
    
    // Get all incomplete tasks for today
    final todayTasks = _tasks
        .where((task) => 
          !task.isCompleted && // Only consider incomplete tasks
          task.dueDate.year == now.year && 
          task.dueDate.month == now.month && 
          task.dueDate.day == now.day)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (todayTasks.isEmpty) {
      // If no incomplete tasks, return one slot for the whole remaining day
      return [TimeSlot(start: startOfDay, end: endOfDay)];
    }

    List<TimeSlot> availableSlots = [];
    DateTime currentTime = startOfDay;

    // Find gaps between incomplete tasks
    for (var task in todayTasks) {
      // Calculate task's time window
      final taskStartTime = task.dueDate;
      final taskEndTime = task.dueDate.add(Duration(minutes: task.estimatedTime));
      
      // Skip if the task is completely in the past
      if (taskEndTime.isBefore(now)) {
        continue;
      }
      
      // If task is currently in progress
      if (now.isAfter(taskStartTime) && now.isBefore(taskEndTime)) {
        currentTime = taskEndTime;
        continue;
      }

      // If there's a gap between current time and next task's start time
      if (taskStartTime.isAfter(currentTime)) {
        // Only add the gap if it starts after now
        if (currentTime.isAfter(now) || currentTime.isAtSameMomentAs(now)) {
          availableSlots.add(TimeSlot(
            start: currentTime,
            end: taskStartTime,
          ));
        } else if (now.isBefore(taskStartTime)) {
          // If current time is before now but there's still a gap until next task
          availableSlots.add(TimeSlot(
            start: now,
            end: taskStartTime,
          ));
        }
      }
      
      // Move current time to task end time
      currentTime = taskEndTime;
    }

    // Add final slot if there's time after the last task
    if (currentTime.isAfter(now) && currentTime.isBefore(endOfDay)) {
      availableSlots.add(TimeSlot(
        start: currentTime,
        end: endOfDay,
      ));
    }

    // Filter out slots that are too short (less than 10 minutes)
    return availableSlots
        .where((slot) => slot.duration.inMinutes >= 10)
        .toList();
  }
}
