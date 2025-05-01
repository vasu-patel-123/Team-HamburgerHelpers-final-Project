import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:taskii/pages/add_task/add_task_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestHelper {
  static Future<void> pumpAddTaskPage(
    WidgetTester tester, {
    required FirebaseAuth auth,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: AddTaskPage(auth: auth),
      ),
    );
    await tester.pumpAndSettle();
  }

  static Future<void> fillTaskForm(
    WidgetTester tester, {
    String? taskName,
    String? description,
    String? priority,
    String? category,
  }) async {
    if (taskName != null) {
      final taskNameField = find.byKey(const Key('taskNameField'));
      await tester.enterText(taskNameField, taskName);
    }
    if (description != null) {
      final descriptionField = find.byKey(const Key('descriptionField'));
      await tester.enterText(descriptionField, description);
    }
    if (priority != null) {
      final priorityDropdown =
          find.byType(DropdownButtonFormField<String>).first;
      await tester.tap(priorityDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text(priority).last);
      await tester.pumpAndSettle();
    }
    if (category != null) {
      final categoryDropdown =
          find.byType(DropdownButtonFormField<String>).last;
      await tester.tap(categoryDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text(category).last);
      await tester.pumpAndSettle();
    }
  }

  static Future<void> selectDate(WidgetTester tester, DateTime date) async {
    final dateField = find.text(
      DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    await tester.tap(dateField);
    await tester.pumpAndSettle();

    final datePicker = find.byType(CalendarDatePicker);
    await tester.pumpAndSettle();

    final dayButton = find.text(date.day.toString());
    await tester.tap(dayButton);
    await tester.pumpAndSettle();

    final okButton = find.text('OK');
    await tester.tap(okButton);
    await tester.pumpAndSettle();
  }

  static Future<void> selectTime(WidgetTester tester, TimeOfDay time) async {
    final timeField = find.text(
      TimeOfDay.now().format(TestHelper.getTestContext(tester)),
    );
    await tester.tap(timeField);
    await tester.pumpAndSettle();

    final timePicker = find.byType(TimePickerDialog);
    await tester.pumpAndSettle();

    final hourButton = find.text(time.hour.toString());
    await tester.tap(hourButton);
    await tester.pumpAndSettle();

    final minuteButton = find.text(time.minute.toString());
    await tester.tap(minuteButton);
    await tester.pumpAndSettle();

    final okButton = find.text('OK');
    await tester.tap(okButton);
    await tester.pumpAndSettle();
  }

  static BuildContext getTestContext(WidgetTester tester) {
    final element = tester.element(find.byType(MaterialApp));
    return element;
  }
}
