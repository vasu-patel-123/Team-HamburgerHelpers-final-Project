import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const NavigationExample()
    );
  }
}

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0;
  final TaskService _taskService = TaskService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Controllers for text fields
  TextEditingController taskNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  // Date and time
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  // Priority
  String priority = 'Low'; // Default priority
  // Reminder
  bool setReminder = false;

  // Form Key for validation
  final _formKey = GlobalKey<FormState>();

  // Calendar related variables
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<Map<String, String>>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadTasks();
  }

  void _loadTasks() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      _taskService.getUserTasks(userId).listen(
        (tasks) {
          setState(() {
            _tasks = tasks;
            _isLoading = false;
            _generateEvents(); // Generate events after tasks are loaded
          });
        },
        onError: (error) {
          setState(() {
            _errorMessage = error.toString();
            _isLoading = false;
          });
          _showErrorSnackBar(error.toString());
        },
      );
    } else {
      setState(() {
        _errorMessage = 'User not authenticated';
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
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

  // Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Time Picker
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
        timeController.text = picked.format(context);
      });
    }
  }

  void _generateEvents() {
    Map<DateTime, List<Map<String, String>>> tempEvents = {};

    for (var task in _tasks) {
      DateTime date = task.dueDate;

      if (!tempEvents.containsKey(date)) {
        tempEvents[date] = [];
      }
      // Convert task to Map<String, String>
      Map<String, String> taskMap = {
        'title': task.title,
        'description': task.description ?? '',
        'priority': task.priority ?? 'Low',
        'date': DateFormat('yyyy-MM-dd').format(task.dueDate),
        'id': task.id,
      };
      tempEvents[date]!.add(taskMap);
        }
    setState(() {
      _events = tempEvents;
    });
  }

  Widget _buildTaskList() {
    final tasks = _getTasksForDay(_selectedDay!);

    if (tasks.isEmpty) {
      return Center(child: Text('No tasks for this day'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        String priority = task['priority'] ?? 'Low';
        Color priorityColor;

        switch (priority) {
          case 'High':
            priorityColor = Colors.red;
            break;
          case 'Medium':
            priorityColor = Colors.orange;
            break;
          case 'Low':
          default:
            priorityColor = Colors.green;
            break;
        }

        return Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: priorityColor, width: 6),
              top: BorderSide(color: Colors.grey.shade400, width: 1),
              right: BorderSide(color: Colors.grey.shade400, width: 1),
              bottom: BorderSide(color: Colors.grey.shade400, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task['title'] ?? '',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(task['date'] ?? '',
                        style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              ),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              IconButton(
                icon: Icon(Icons.edit, color: const Color.fromARGB(255, 65, 67, 72)),
                onPressed: () {
                  // Optional: open edit form
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, String>> _getTasksForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingIndicator();
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    final ThemeData theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.amber,
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
      body:
          <Widget>[
            /// Home page
            Scaffold(
              /// top bar
              appBar: AppBar(
                shape: Border(
                bottom: BorderSide(
                  color: const Color.fromARGB(255, 153, 142, 126),
                  width: 4
                  )
                ),
                elevation: 4,
                title: const Text('Today'),
                /// profile button
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.person_2_outlined),
                    onPressed: () {
                      // handle the press
                    },
                  ),
                ],
              ),
            ),

            /// Tasks page
            Scaffold(
              /// top bar
              appBar: AppBar(
                shape: Border(
                bottom: BorderSide(
                  color: const Color.fromARGB(255, 153, 142, 126),
                  width: 4
                  )
                ),
                elevation: 4,
                title: const Text('Tasks'),
                /// profile button
                actions: <Widget>[
                  SizedBox(
                    width: 100,
                    child: TextButton(
                      onPressed: () {
                        debugPrint('Add task pressed');
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 120, 205, 233),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        '+ ADD Task',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              body: ListView.builder(
                padding: EdgeInsets.all(12),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  String priority = task.priority ?? 'Low';
                  Color priorityColor;

                  switch (priority) {
                    case 'High':
                      priorityColor = Colors.red;
                      break;
                    case 'Medium':
                      priorityColor = Colors.orange; // better contrast than yellow
                      break;
                    case 'Low':
                    default:
                      priorityColor = Colors.green;
                      break;
                  }

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: priorityColor, width: 6), // colored left edge
                        top: BorderSide(color: Colors.grey.shade400, width: 1),
                        right: BorderSide(color: Colors.grey.shade400, width: 1),
                        bottom: BorderSide(color: Colors.grey.shade400, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(task.title ?? '',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text(task.dueDate != null ? DateFormat('yyyy-MM-dd').format(task.dueDate) : '',
                                  style: TextStyle(color: Colors.grey.shade700)),
                            ],
                          ),
                        ),

                        // Priority label with oval background
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: priorityColor, // Background color based on priority
                            borderRadius: BorderRadius.circular(20), // Oval shape
                          ),
                          child: Text(
                            priority,
                            style: TextStyle(
                              color: Colors.black, // Black text color
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        /// edit button
                        IconButton(
                          icon: Icon(Icons.edit, color: const Color.fromARGB(255, 65, 67, 72)),
                          onPressed: () {
                            // Handle edit logic
                            print("Edit task: ${task.title}");
                          },
                        ),
                      ],
                    ),
                  );
                },
              )
            ),

            /// Add task page
            Scaffold(
              /// top bar
              appBar: AppBar(
                shape: Border(
                bottom: BorderSide(
                  color: const Color.fromARGB(255, 153, 142, 126),
                  width: 4
                  )
                ),
                elevation: 4,
                title: const Text('ADD Task'),
              ),
              body: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          children: <Widget>[
                            // Task Name
                            TextFormField(
                              controller: taskNameController,
                              decoration: InputDecoration(
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
                            SizedBox(height: 12),

                            // Task Due Date/Time
                            Row(
                              children: <Widget>[
                                //Date field
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(context),
                                    child: AbsorbPointer(
                                      child: TextFormField(
                                        controller: dateController,
                                        decoration: InputDecoration(
                                          labelText: 'Due Date',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12),
                                //time field
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectTime(context),
                                    child: AbsorbPointer(
                                      child: TextFormField(
                                        controller: timeController,
                                        decoration: InputDecoration(
                                          labelText: 'Due Time',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),

                            // Priority
                            DropdownButtonFormField<String>(
                              value: priority,
                              onChanged: (String? newValue) {
                                setState(() {
                                  priority = newValue!;
                                });
                              },
                              items: ['Low', 'Medium', 'High']
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              decoration: InputDecoration(
                                labelText: 'Priority',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 12),

                            // Description
                            TextFormField(
                              controller: descriptionController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 12),

                            // Category
                            TextFormField(
                              controller: categoryController,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 12),

                            // Reminder Section
                            SwitchListTile(
                              title: Text('Set Reminder'),
                              value: setReminder,
                              onChanged: (bool value) {
                                setState(() {
                                  setReminder = value;
                                });
                              },
                            ),
                            SizedBox(height: 12),

                            // Submit Button
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState?.validate() ?? false) {
                                  _addTask();
                                }
                              },
                              child: Text('Save Task'),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            /// Calandar page
            Scaffold(
              /// top bar
              appBar: AppBar(
                shape: Border(
                bottom: BorderSide(
                  color: const Color.fromARGB(255, 153, 142, 126),
                  width: 4
                  )
                ),
                elevation: 4,
                title: const Text('Calendar'),
                
                actions: <Widget>[
                  /// add button
                  IconButton(
                    icon: const Icon(Icons.add),
                    
                    onPressed: () {
                      // handle the press
                    },
                  ),
                  /// filter button
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    
                    onPressed: () {
                      // handle the press
                    },
                  ),
                ],
              ),
              body: Column(
                      children: [
                        TableCalendar(
                          firstDay: DateTime(2020),
                          lastDay: DateTime(2100),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          calendarFormat: _calendarFormat,
                          onFormatChanged: (format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          },

                          eventLoader: _getTasksForDay,
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          calendarStyle: CalendarStyle(
                            markerDecoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          availableCalendarFormats: const {
                            CalendarFormat.month: 'Week',
                            CalendarFormat.twoWeeks: 'Month',
                            CalendarFormat.week: '2 Weeks',
                          },
                        ),


                        const SizedBox(height: 8.0),
                        Expanded(
                          child: _buildTaskList(),
                        ),
                      ],
                    ),
            ),

            /// Stats page
            /// Add task page
            Scaffold(
              /// top bar
              appBar: AppBar(
                shape: Border(
                bottom: BorderSide(
                  color: const Color.fromARGB(255, 153, 142, 126),
                  width: 4
                  )
                ),
                elevation: 4,
                title: const Text('Stats'),
              ),
            ),

          ][currentPageIndex],
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

  Future<void> _addTask() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      _showErrorSnackBar('User not authenticated');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final task = Task(
        id: const Uuid().v4(),
        title: taskNameController.text,
        description: descriptionController.text,
        dueDate: DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        ),
        priority: priority,
        userId: userId,
      );

      await _taskService.createTask(task);
      
      // Clear controllers
      taskNameController.clear();
      descriptionController.clear();
      categoryController.clear();
      dateController.clear();
      timeController.clear();
      
      // Reset to default values
      setState(() {
        selectedDate = DateTime.now();
        selectedTime = TimeOfDay.now();
        priority = 'Low';
        _isLoading = false;
      });

      _showSuccessSnackBar('Task created successfully!');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    try {
      await _taskService.toggleTaskCompletion(task.id, !task.isCompleted);
      _showSuccessSnackBar('Task ${task.isCompleted ? 'completed' : 'marked as incomplete'}');
    } catch (e) {
      _showErrorSnackBar('Failed to update task: ${e.toString()}');
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await _taskService.deleteTask(taskId);
      _showSuccessSnackBar('Task deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete task: ${e.toString()}');
    }
  }
}
