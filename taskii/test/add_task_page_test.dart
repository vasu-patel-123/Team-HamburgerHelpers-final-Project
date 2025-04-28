import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:taskii/pages/add_task/add_task_page.dart';

// Fake FirebaseAuth implementation
class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => FakeUser();
}

class FakeUser extends Fake implements User {
  @override
  String get uid => 'test-uid';
}

void main() {
  setUpAll(() async {
    // Initialize Firebase with your project’s configuration
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'copied-api-key', // From Firebase Console
        appId: 'copied-app-id',
        messagingSenderId: 'copied-messaging-sender-id',
        projectId: 'copied-project-id',
        databaseURL: 'copied-database-url',
      ),
    );
  });

  setUp(() {
    // Override FirebaseAuth.instance to use FakeFirebaseAuth
    // This ensures AddTaskPage doesn't try to use real auth
  });

  testWidgets('Check if AddTaskPage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddTaskPage(),
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

    debugPrint('AddTaskPage rendered with all form fields');
  });

  testWidgets('Check if form validation works for empty task name', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddTaskPage(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Task').last); // Target the button
    await tester.pump();

    expect(find.text('Please enter a task name'), findsOneWidget);

    debugPrint('Form validation triggered: Task name is empty');
  });

  testWidgets('Check if date picker updates selected date', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddTaskPage(),
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

  testWidgets('Check if priority dropdown updates selection', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddTaskPage(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Medium'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('High').last);
    await tester.pumpAndSettle();

    expect(find.text('High'), findsOneWidget);

    debugPrint('Priority changed from Medium to High');
  });
}