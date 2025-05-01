import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Theme Mode Tests', () {
    testWidgets('should correctly display light theme', (
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

      await tester.pumpAndSettle();

      expect(find.text('Dark Mode: Yes'), findsOneWidget);
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, equals(Colors.grey[900]));
    });

    testWidgets('should switch between themes smoothly', (
      WidgetTester tester,
    ) async {
      final app = MaterialApp(
        themeMode: ThemeMode.system,
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
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Switch to dark theme
      await tester.pumpWidget(
        MaterialApp(
          themeMode: ThemeMode.dark,
          theme: app.theme,
          darkTheme: app.darkTheme,
          home: app.home,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dark Mode: Yes'), findsOneWidget);
      final darkCard = tester.widget<Card>(find.byType(Card));
      expect(darkCard.color, equals(Colors.grey[900]));

      // Switch back to light theme
      await tester.pumpWidget(
        MaterialApp(
          themeMode: ThemeMode.light,
          theme: app.theme,
          darkTheme: app.darkTheme,
          home: app.home,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dark Mode: No'), findsOneWidget);
      final lightCard = tester.widget<Card>(find.byType(Card));
      expect(lightCard.color, equals(Colors.white));
    });
  });

  group('Theme Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should persist theme preference', (WidgetTester tester) async {
      // TODO: Implement theme persistence tests
      // This would require mocking SharedPreferences and testing the actual
      // theme persistence implementation in your app
    });
  });
}
