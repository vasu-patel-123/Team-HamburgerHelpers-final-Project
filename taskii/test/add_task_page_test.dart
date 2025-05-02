import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:taskii/screens/add_task_page.dart';
import 'add_task_page_test.mocks.dart';
import 'firebase_mock.dart';

@GenerateMocks([FirebaseAuth, User, DatabaseReference, DataSnapshot])
void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;
  late MockDatabaseReference mockDatabaseRef;
  late MockDatabaseReference mockChildRef;
  late MockDatabaseReference mockPushRef;

  setUpAll(() async {
    await setupFirebaseCoreMocks();
    setupFirebaseAuthMocks();
  });

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockDatabaseRef = MockDatabaseReference();
    mockChildRef = MockDatabaseReference();
    mockPushRef = MockDatabaseReference();
    mockPushRef = MockDatabaseReference();

    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockDatabaseRef.child('tasks')).thenReturn(mockChildRef);
    when(mockChildRef.push()).thenReturn(mockPushRef);
    when(mockPushRef.set(any)).thenAnswer((_) => Future.value());
  });

  testWidgets('Add Task Page UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddTaskPage(
          firebaseAuth: mockFirebaseAuth,
          databaseRef: mockDatabaseRef,
        ),
      ),
    );

    // Verify initial UI elements
    expect(find.text('Add New Task'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('Add Task Form Submission Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddTaskPage(
          firebaseAuth: mockFirebaseAuth,
          databaseRef: mockDatabaseRef,
        ),
      ),
    );

    // Fill in the form
    await tester.enterText(find.byType(TextField).first, 'Test Task');
    await tester.enterText(find.byType(TextField).last, 'Test Description');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('High'));
    await tester.pumpAndSettle();

    // Submit the form
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Verify database interaction
    verify(mockDatabaseRef.child('tasks')).called(1);
    verify(mockChildRef.push()).called(1);
    verify(mockPushRef.set(any)).called(1);
  });
}
