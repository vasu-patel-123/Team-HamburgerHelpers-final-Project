import 'package:flutter/material.dart';

/// Flutter code sample for [NavigationBar].



class homePage extends StatelessWidget {
  const homePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: ThemeData(useMaterial3: true),  home: const NavigationExample());
  }
}

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.amber,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_rounded),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'stats',
          ),
        ],
      ),
      body:
          <Widget>[
            /// Home page
            Scaffold(
              /// top bar
              appBar: AppBar(
                title: const Text('Today'),
                /// profile button
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.person_2_outlined),
                    
                    onPressed: () {
                      // handle the press
                    },
                  ),
                ],
              ),
            ),

            /// Tasks page
            Card(
              shadowColor: Colors.transparent,
              margin: const EdgeInsets.all(8.0),
              child: SizedBox.expand(
                child: Center(child: Text('tasks page', style: theme.textTheme.titleLarge)),
              ),
            ),

            /// Add page
            Card(
              shadowColor: Colors.transparent,
              margin: const EdgeInsets.all(8.0),
              child: SizedBox.expand(
                child: Center(child: Text('add page', style: theme.textTheme.titleLarge)),
              ),
            ),

            /// Calandar page
            Card(
              shadowColor: Colors.transparent,
              margin: const EdgeInsets.all(8.0),
              child: SizedBox.expand(
                child: Center(child: Text('calandar page', style: theme.textTheme.titleLarge)),
              ),
            ),

            /// Stats page
            Card(
              shadowColor: Colors.transparent,
              margin: const EdgeInsets.all(8.0),
              child: SizedBox.expand(
                child: Center(child: Text('Stats page', style: theme.textTheme.titleLarge)),
              ),
            ),

          ][currentPageIndex],
    );
  }
}