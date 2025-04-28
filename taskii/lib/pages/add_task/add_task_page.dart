import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

// Mock widget to simulate AddTaskPage without Firebase dependencies
class MockAddTaskPage extends StatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialTime;

  const MockAddTaskPage({
    super.key,
    this.initialDate,
    this.initialTime,
  });

  @override
  State<MockAddTaskPage> createState() => _MockAddTaskPageState();
}

class _MockAddTaskPageState extends State<MockAddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
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

    // Simulate task creation without Firebase
    await Future.delayed(const Duration(milliseconds: 100)); // Mimic async

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      } else {
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

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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
                          backgroundColor: Colors.black,
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

void main() {
  testWidgets('Check if MockAddTaskPage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MockAddTaskPage(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Add Task'), findsAtLeastNWidgets(1)); // AppBar title and button
    expect(find.text('Task Name'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Priority'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Due Date'), findsOneWidget);
    expect(find.text('Due Time'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing); // Not loading

    debugPrint('MockAddTaskPage rendered with all form fields');
  });

  testWidgets('Check if form validation works for empty task name', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MockAddTaskPage(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Task').last); // Target the button
    await tester.pump();

    expect(find.text('Please enter a task name'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing); // No success SnackBar

    debugPrint('Form validation triggered: Task name is empty');
  });

  testWidgets('Check if priority dropdown updates selection', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MockAddTaskPage(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Medium'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('High').last);
    await tester.pumpAndSettle();

    expect(find.text('High'), findsOneWidget);
    expect(find.text('Medium'), findsNothing);

    debugPrint('Priority changed from Medium to High');
  });

  testWidgets('Check if category dropdown updates selection', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MockAddTaskPage(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('General'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>).last); // Second dropdown
    await tester.pumpAndSettle();

    await tester.tap(find.text('Work').last);
    await tester.pumpAndSettle();

    expect(find.text('Work'), findsOneWidget);
    expect(find.text('General'), findsNothing);

    debugPrint('Category changed from General to Work');
  });

  testWidgets('Check if date picker updates selected date', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MockAddTaskPage(),
      ),
    );

    await tester.pumpAndSettle();

    final initialDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    expect(find.text(initialDate), findsOneWidget);

    await tester.tap(find.text(initialDate));
    await tester.pumpAndSettle();

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await tester.tap(find.text(tomorrow.day.toString()));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final newDate = DateFormat('yyyy-MM-dd').format(tomorrow);
    expect(find.text(newDate), findsOneWidget);

    debugPrint('Date changed from $initialDate to $newDate');
  });

  testWidgets('Check if time picker updates selected time', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MockAddTaskPage(),
      ),
    );

    await tester.pumpAndSettle();

    final initialTime = TimeOfDay.now().format(tester.element(find.byType(MaterialApp)));
    expect(find.text(initialTime), findsOneWidget);

    await tester.tap(find.text(initialTime));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK')); // Select current time for simplicity
    await tester.pumpAndSettle();

    expect(find.text(initialTime), findsOneWidget); // Time unchanged for this test

    debugPrint('Time picker tested');
  });

  testWidgets('Check if task submission shows success SnackBar', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MockAddTaskPage(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Test Task');
    await tester.tap(find.text('Add Task').last);
    await tester.pumpAndSettle();

    expect(find.text('Task added successfully!'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);

    debugPrint('Task submission showed success SnackBar');
  });
}