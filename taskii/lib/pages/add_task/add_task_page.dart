import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:taskii/models/task.dart';
import 'package:taskii/services/task_service.dart';

class AddTaskPage extends StatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final VoidCallback? onExit;
  final FirebaseAuth? auth;

  const AddTaskPage({
    super.key,
    this.initialDate,
    this.initialTime,
    this.onExit,
    this.auth,
  });

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedPriority = 'Medium';
  String _selectedCategory = 'General';
  int _selectedEstimatedTime = 30; // Default to 30 minutes
  bool _isLoading = false;
  late final FirebaseAuth _auth;
  late final TaskService _taskService;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedTime = widget.initialTime ?? TimeOfDay.now();
    _auth = widget.auth ?? FirebaseAuth.instance;
    _taskService = TaskService(auth: _auth);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _addTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final dueDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final task = Task(
        id: const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: dueDate,
        priority: _selectedPriority,
        category: _selectedCategory,
        isCompleted: false,
        userId: userId,
        estimatedTime: _selectedEstimatedTime,
        creationDate: DateTime.now(),
      );

      await _taskService.createTask(task);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task added successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.onExit != null) {
          widget.onExit!();
        } else if (Navigator.of(context).canPop()) {
          Navigator.pop(context);
        } else {
          _titleController.clear();
          _descriptionController.clear();
          setState(() {
            _selectedDate = DateTime.now();
            _selectedTime = TimeOfDay.now();
            _selectedPriority = 'Medium';
            _selectedCategory = 'General';
            _selectedEstimatedTime = 30;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add task: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: const Border(
          bottom: BorderSide(
            color: Color.fromARGB(255, 153, 142, 126),
            width: 4,
          ),
        ),
        elevation: 4,
        title: const Text('Add Task'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        key: const Key('taskNameField'),
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Task Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a task name';
                          }
                          if (value.length > 100) {
                            return 'Task name must be less than 100 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('descriptionField'),
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            [
                              'Dark Souls',
                              'Medium',
                              'Low',
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedPriority = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            [
                              'General',
                              'Work',
                              'Personal',
                              'Shopping',
                              'Health',
                              'Education',
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _selectedEstimatedTime,
                        decoration: const InputDecoration(
                          labelText: 'Estimated Time to Complete',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            [
                              15,
                              30,
                              45,
                              60,
                              90,
                              120,
                              150,
                              180,
                              210,
                              240,
                            ].map<DropdownMenuItem<int>>((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value minutes'),
                              );
                            }).toList(),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedEstimatedTime = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Due Date',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(_selectedDate),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Due Time',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(_selectedTime.format(context)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _addTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Add Task',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
