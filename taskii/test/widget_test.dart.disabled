// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:taskii/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskii/mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test',
        appId: 'test',
        messagingSenderId: 'test',
        projectId: 'test',
      ),
    );
  });

  testWidgets('shows login screen with assignment icon', (WidgetTester tester) async {
    await tester.pumpWidget(const Taskii());
    await tester.pumpAndSettle();
    expect(find.byType(LoginPageSignUp), findsOneWidget);
    expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
  });
}
