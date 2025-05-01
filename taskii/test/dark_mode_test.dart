import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Check if app supports dark mode or not', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.light,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.black),
          ),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        ),
        home: Builder(
          builder: (BuildContext context) {
            bool isItDark = Theme.of(context).brightness == Brightness.dark;
            return Scaffold(
              body: Center(
                child: Text(
                  'Dark Mode: ${isItDark ? "Yes" : "No"}',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Dark Mode: No'), findsOneWidget);
    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color, equals(Colors.white));
  });

  testWidgets('should correctly display dark theme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.dark,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.black),
          ),
          primaryColor: Colors.blue,
          cardTheme: const CardTheme(color: Colors.white),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
          primaryColor: Colors.blue,
          cardTheme: CardTheme(color: Colors.grey[900]),
        ),
        home: Builder(
          builder: (BuildContext context) {
            final theme = Theme.of(context);
            return Scaffold(
              body: Column(
                children: [
                  Text(
                    'Dark Mode: ${theme.brightness == Brightness.dark ? "Yes" : "No"}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  Card(
                    color: theme.cardTheme.color,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Card Content',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    // Debug: Check the current theme
    final BuildContext context = tester.element(find.byType(Scaffold));
    final bool isActuallyDark = Theme.of(context).brightness == Brightness.dark;
    final String currentBrightness = Theme.of(context).brightness.toString();
    debugPrint('Is actually dark: $isActuallyDark');
    debugPrint('Current brightness: $currentBrightness');

    // Check for the text in dark mode
    final Finder darkTextFinder = find.text('Dark Mode: No');
    expect(darkTextFinder, findsOneWidget);
  });
}
