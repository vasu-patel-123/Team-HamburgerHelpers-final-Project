// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:taskii/mock.dart';
import 'package:taskii/main.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp(
      name: 'test',
      options: const FirebaseOptions(
        apiKey: 'test',
        appId: 'test',
        messagingSenderId: 'test',
        projectId: 'test',
      ),
    );
  });

  testWidgets('App shows login page', (WidgetTester tester) async {
    final mockAuth = MockFirebaseAuth();
    await tester.pumpWidget(Taskii(firebaseAuth: mockAuth));
    expect(find.byType(LoginPageSignUp), findsOneWidget);
    expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
  });
}
