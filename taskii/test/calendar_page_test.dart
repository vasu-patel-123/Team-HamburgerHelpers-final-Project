import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/table_calendar.dart';
import '../lib/pages/calendar/calendar_page.dart';
import '../lib/models/task.dart';

void main() {
  testWidgets('Task appears on correct date in CalendarPage with correct priority', (WidgetTester tester) async {
    // Use today's date to ensure the calendar shows the correct month
    final now = DateTime.now();
    final DateTime testDate = DateTime(now.year, now.month, now.day, 10, 0);
    final String testTitle = 'Test Calendar Task';

    // Create a dummy task for today with High priority
    final task = Task(
      id: '1',
      title: testTitle,
      description: 'Test Description',
      dueDate: testDate,
      priority: 'High',
      category: 'General',
      isCompleted: false,
      userId: 'user1',
      estimatedTime: 30,
    );

    // Build the CalendarPage with the task
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarPage(
          key: const Key('calendar_page'),
          tasks: [task],
          onTaskCompletion: (_) {},
          onTaskDelete: (_) {},
          onFilterApply: (_, __, ___, ____, _____) {},
          onFilterClear: () {},
          onRefresh: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap today's date in the calendar
    final dayFinder = find.text(testDate.day.toString());
    expect(dayFinder, findsWidgets, reason: 'Could not find the day number in the calendar');
    await tester.tap(dayFinder.first);
    await tester.pumpAndSettle();

    // The task title should appear in the list for that day
    expect(find.text(testTitle), findsOneWidget, reason: 'Could not find the task title');

    // Find the task item container
    final taskItemContainer = find.ancestor(
      of: find.text(testTitle),
      matching: find.byType(Container),
    ).first;

    // Find the Row that contains the task title
    final taskRow = find.ancestor(
      of: find.text(testTitle),
      matching: find.byType(Row),
    ).first;

    // Find all Containers in the Row
    final containerFinder = find.descendant(
      of: taskRow,
      matching: find.byType(Container),
    );
    
    expect(containerFinder, findsWidgets, reason: 'No containers found in the task row');
    
    final priorityContainer = containerFinder.first;
    final container = tester.widget<Container>(priorityContainer);
    final decoration = container.decoration as BoxDecoration;
    
    // High priority should be red
    expect(decoration.color, equals(Colors.red), reason: 'Priority color should be red for High priority tasks');
  });
} 