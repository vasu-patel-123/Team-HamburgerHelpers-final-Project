import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../widgets/task_item.dart';

class TasksPage extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task) onTaskCompletion;
  final Function(Task) onTaskDelete;
  final Function(String, bool, bool, DateTime?, DateTime?) onFilterApply;
  final Function() onFilterClear;

  const TasksPage({
    super.key,
    required this.tasks,
    required this.onTaskCompletion,
    required this.onTaskDelete,
    required this.onFilterApply,
    required this.onFilterClear,
  });

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final TaskService _taskService = TaskService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _subscription;

  // Filter state variables
  String _selectedPriority = 'All';
  bool _showCompleted = true;
  bool _showIncomplete = true;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  void initState() {
    super.initState();
    _loadTasks(showLoading: true); // Only show loading on first load
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _loadTasks({bool showLoading = false}) {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    _subscription = _taskService
        .getUserTasks(_auth.currentUser?.uid ?? '')
        .listen(
          (tasks) {
            if (mounted) {
              setState(() {
                _tasks = tasks;
                _filteredTasks = List.from(tasks);
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
        estimatedTime: task.estimatedTime,
      );

      await _taskService.updateTask(updatedTask);

      setState(() {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = updatedTask;
          _filteredTasks = List.from(_tasks);
        }
      });

      _showSnackBar(
        'Task ${task.isCompleted ? "uncompleted" : "completed"}!',
        isError: false,
      );
    } catch (e) {
      _showSnackBar('Failed to update task: ${e.toString()}');
    }
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await _taskService.deleteTask(task.id);
      setState(() {
        _tasks.removeWhere((t) => t.id == task.id);
        _filteredTasks = List.from(_tasks);
      });
      _showSnackBar('Task deleted successfully!', isError: false);
    } catch (e) {
      _showSnackBar('Failed to delete task: ${e.toString()}');
    }
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

  void _showFilterDialog() {
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
                    DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          [
                            'All',
                            'High',
                            'Medium',
                            'Low',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPriority = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Show Tasks:'),
                    CheckboxListTile(
                      title: const Text('Completed'),
                      value: _showCompleted,
                      onChanged: (bool? value) {
                        setState(() {
                          _showCompleted = value!;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Incomplete'),
                      value: _showIncomplete,
                      onChanged: (bool? value) {
                        setState(() {
                          _showIncomplete = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Date Range:'),
                    ListTile(
                      title: Text(
                        _filterStartDate == null
                            ? 'Select Start Date'
                            : DateFormat(
                              'yyyy-MM-dd',
                            ).format(_filterStartDate!),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _filterStartDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _filterStartDate = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: Text(
                        _filterEndDate == null
                            ? 'Select End Date'
                            : DateFormat('yyyy-MM-dd').format(_filterEndDate!),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _filterEndDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _filterEndDate = picked;
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
                    _clearFilters();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Clear Filters'),
                ),
                TextButton(
                  onPressed: () {
                    _applyFilters();
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

  void _applyFilters() {
    setState(() {
      _filteredTasks =
          _tasks.where((task) {
            if (_selectedPriority != 'All' &&
                task.priority != _selectedPriority) {
              return false;
            }

            if (!_showCompleted && task.isCompleted) {
              return false;
            }
            if (!_showIncomplete && !task.isCompleted) {
              return false;
            }

            // Calculate the task's time window
            final now = DateTime.now();
            final taskEndTime = task.dueDate.add(
              Duration(minutes: task.estimatedTime),
            );

            // If the task is still within its time window, show it in current section
            if (now.isBefore(taskEndTime)) {
              return true;
            }

            // For tasks outside their time window, apply date filters
            if (_filterStartDate != null &&
                task.dueDate.isBefore(_filterStartDate!)) {
              return false;
            }
            if (_filterEndDate != null &&
                task.dueDate.isAfter(_filterEndDate!)) {
              return false;
            }

            return true;
          }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedPriority = 'All';
      _showCompleted = true;
      _showIncomplete = true;
      _filterStartDate = null;
      _filterEndDate = null;
      _filteredTasks = List.from(_tasks);
    });
  }

  Future<void> _refreshTasks() async {
    _loadTasks(
      showLoading: false,
    ); // Don't show full loading on pull-to-refresh
    setState(() {});
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
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        shape: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 4,
          ),
        ),
        elevation: 4,
        centerTitle: true,
        title: const Text('Tasks'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTasks,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            12,
            28,
            12,
            12,
          ), // <-- Add top padding here
          itemCount: _filteredTasks.length,
          itemBuilder: (context, index) {
            final task = _filteredTasks[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TaskItem(
                task: task,
                priorityColor: _getPriorityColor(task.priority),
                onToggleComplete: _toggleTaskCompletion,
                onDelete: _deleteTask,
                showDescription: true, // <-- Pass this to TaskItem
              ),
            );
          },
        ),
      ),
    );
  }
}
