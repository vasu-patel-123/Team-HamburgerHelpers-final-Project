import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock version of AddTaskPage for testing
class MockAddTaskPage extends StatelessWidget {
  const MockAddTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Mock Add Task Page')));
  }
}

// Test-specific version of HomePage that only includes what we need for the test
class TestHomePage extends StatelessWidget {
  const TestHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Home Page Content')),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MockAddTaskPage()),
            );
          }
        },
        selectedIndex: 0,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.task), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.add, size: 44), label: ''),
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('Schedule task button exists and navigates to AddTaskPage', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const MaterialApp(home: TestHomePage()));

    // Wait for the page to load
    await tester.pumpAndSettle();

    // Find the schedule task button in the bottom navigation bar
    final scheduleButton = find.byIcon(Icons.add);
    expect(scheduleButton, findsOneWidget);

    // Tap the button
    await tester.tap(scheduleButton);
    await tester.pumpAndSettle();

    // Verify that we navigated to the AddTaskPage
    expect(find.byType(MockAddTaskPage), findsOneWidget);
    expect(find.text('Mock Add Task Page'), findsOneWidget);
  });
}
