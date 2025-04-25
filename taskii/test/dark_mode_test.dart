import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Check if app supports dark mode or not', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      themeMode: ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black)),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
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
    ));

    await tester.pumpAndSettle(); // <-- Wait for frame

    final Finder lightTextFinder = find.text('Dark Mode: No');
    expect(lightTextFinder, findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black)),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      home: Builder(
        builder: (BuildContext context) {
          bool isDarkNow = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            body: Center(
              child: Text(
                'Dark Mode: ${isDarkNow ? "Yes" : "No"}',
                style: TextStyle(fontSize: 20),
              ),
            ),
          );
        },
      ),
    ));

    await tester.pumpAndSettle(); // <-- Wait for frame

    final Finder darkTextFinder = find.text('Dark Mode: Yes');
    expect(darkTextFinder, findsOneWidget);
  });
}
