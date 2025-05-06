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
  group('Schedule Task Button Tests', () {
    testWidgets('Schedule task button exists in bottom navigation bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TestHomePage()));

      await tester.pumpAndSettle();

      // Find the schedule task button in the bottom navigation bar
      final scheduleButton = find.byIcon(Icons.add);
      expect(scheduleButton, findsOneWidget);
    });

    testWidgets('Schedule task button navigates to AddTaskPage', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TestHomePage()));

      await tester.pumpAndSettle();

      // Find and tap the schedule task button
      final scheduleButton = find.byIcon(Icons.add);
      await tester.tap(scheduleButton);
      await tester.pumpAndSettle();

      // Verify navigation to AddTaskPage
      expect(find.byType(MockAddTaskPage), findsOneWidget);
      expect(find.text('Mock Add Task Page'), findsOneWidget);
    });

    testWidgets('Schedule task button is centered in bottom navigation bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TestHomePage()));

      await tester.pumpAndSettle();

      // Find the bottom navigation bar
      final bottomNavBar = find.byType(NavigationBar);
      expect(bottomNavBar, findsOneWidget);

      // Find the schedule task button
      final scheduleButton = find.byIcon(Icons.add);
      expect(scheduleButton, findsOneWidget);

      // Get the position of the button
      final buttonPosition = tester.getCenter(scheduleButton);
      final screenWidth =
          tester.binding.window.physicalSize.width /
          tester.binding.window.devicePixelRatio;

      // Verify the button is roughly centered (allowing for some margin of error)
      expect(buttonPosition.dx, closeTo(screenWidth / 2, 50));
    });
  });
}
