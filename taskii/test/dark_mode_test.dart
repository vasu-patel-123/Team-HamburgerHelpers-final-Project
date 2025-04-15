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
