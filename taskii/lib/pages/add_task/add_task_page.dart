import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';

class AddTaskPage extends StatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final VoidCallback? onExit; // <-- Add this

  const AddTaskPage({
    super.key,
    this.initialDate,
    this.initialTime,
    this.onExit,
  });

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final TaskService _taskService = TaskService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedPriority = 'Medium';
  String _selectedCategory = 'General';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedTime = widget.initialTime ?? TimeOfDay.now();
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
      );

      await _taskService.createTask(task);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      // Clear the form fields
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _selectedTime = TimeOfDay.now();
        _selectedPriority = 'Medium';
        _selectedCategory = 'General';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task added successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Check if we can pop the current route
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context);
        } else {
          // If we can't pop, we're probably in the bottom nav bar view
          // Just clear the form and show success message
          _titleController.clear();
          _descriptionController.clear();
          setState(() {
            _selectedDate = DateTime.now();
            _selectedTime = TimeOfDay.now();
            _selectedPriority = 'Medium';
            _selectedCategory = 'General';
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
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Exit',
          onPressed: () {
            if (widget.onExit != null) {
              widget.onExit!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.pop(context);
            } else {
              // Clear the form fields
              _titleController.clear();
              _descriptionController.clear();
              setState(() {
                _selectedDate = DateTime.now();
                _selectedTime = TimeOfDay.now();
                _selectedPriority = 'Medium';
                _selectedCategory = 'General';
              });
            }
          },
        ),
        shape: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 4
          )
        ),
        elevation: 4,
        title: const Text('Add Task'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Task Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a task name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
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
                      items: ['High', 'Medium', 'Low']
                          .map<DropdownMenuItem<String>>((String value) {
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
                      items: ['General', 'Work', 'Personal', 'Shopping', 'Health', 'Education']
                          .map<DropdownMenuItem<String>>((String value) {
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
                                DateFormat('yyyy-MM-dd').format(_selectedDate),
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
                              child: Text(
                                _selectedTime.format(context),
                              ),
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
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Add Task',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
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