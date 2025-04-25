import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/task.dart';

class CalendarPage extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task) onTaskCompletion;
  final Function(Task) onTaskDelete;
  final Function(String, bool, bool, DateTime?, DateTime?) onFilterApply;
  final Function() onFilterClear;
  final Future<void> Function() onRefresh;

  const CalendarPage({
    super.key,
    required this.tasks,
    required this.onTaskCompletion,
    required this.onTaskDelete,
    required this.onFilterApply,
    required this.onFilterClear,
    required this.onRefresh,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // Calendar related variables
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadInitialEvents();
  }

  Future<void> _loadInitialEvents() async {
    setState(() {
      _isLoading = true;
    });
    // Simulate async load if needed, or just generate events
    _generateEvents();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void didUpdateWidget(CalendarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tasks != widget.tasks) {
      _generateEvents();
    }
  }

  void _generateEvents() {
    Map<DateTime, List<Map<String, dynamic>>> tempEvents = {};

    for (var task in widget.tasks) {
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
        'category': task.category,
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
                    widget.onFilterClear();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Clear Filters'),
                ),
                TextButton(
                  onPressed: () {
                    widget.onFilterApply(
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        shape: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 4
          )
        ),
        elevation: 4,
        title: const Text('Calendar'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () {
              _showFilterDialog(context);
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
            availableCalendarFormats: const {
              CalendarFormat.month: 'Week',
              CalendarFormat.twoWeeks: 'Month',
              CalendarFormat.week: '2 Weeks',
            },
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
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                return Positioned(
                  bottom: 1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: widget.onRefresh,
              child: _selectedDay == null
                  ? const Center(child: Text('No day selected'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _getTasksForDay(_selectedDay!).length,
                      itemBuilder: (context, index) {
                        final task = _getTasksForDay(_selectedDay!)[index];
                        String priority = task['priority'];
                        Color priorityColor = _getPriorityColor(priority);

                        return Padding(
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
                                      color: priorityColor,
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
                                            value: task['isCompleted'],
                                            onChanged: (bool? value) {
                                              widget.onTaskCompletion(Task(
                                                id: task['id'],
                                                title: task['title'],
                                                description: task['description'],
                                                dueDate: task['dueDate'],
                                                priority: task['priority'],
                                                category: task['category'],
                                                isCompleted: value ?? false,
                                                userId: task['userId'],
                                              ));
                                            },
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  task['title'],
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    decoration: task['isCompleted'] 
                                                      ? TextDecoration.lineThrough 
                                                      : TextDecoration.none,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  DateFormat('h:mm a').format(task['dueDate']),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red),
                                            onPressed: () {
                                              widget.onTaskDelete(Task(
                                                id: task['id'],
                                                title: task['title'],
                                                description: task['description'],
                                                dueDate: task['dueDate'],
                                                priority: task['priority'],
                                                category: task['category'],
                                                isCompleted: task['isCompleted'],
                                                userId: task['userId'],
                                              ));
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}