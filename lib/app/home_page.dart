import 'package:flutter/material.dart';
import 'package:catch_this_ai/features/tracker/presentation/pages/tracker_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget page = switch (selectedIndex) {
      0 => const TrackerPage(),
      1 => const Placeholder(), // TODO: replace with StatsPage() when ready
      2 => const Placeholder(), // TODO: replace with SettingsPage() when ready
      _ => const SizedBox(),
    };

    final mainArea = ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: page,
      ),
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 450) {
            return Column(
              children: [
                Expanded(child: mainArea),
                SafeArea(
                  top: false,
                  child: BottomNavigationBar(
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.spatial_tracking),
                        label: 'Catch This AI',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.query_stats),
                        label: 'Stats',
                      ),
                    ],
                    currentIndex: selectedIndex,
                    onTap: (value) => setState(() => selectedIndex = value),
                    selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          } else {
            return Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    extended: constraints.maxWidth >= 600,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.favorite),
                        label: Text('Favorites'),
                      ),
                    ],
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (value) =>
                        setState(() => selectedIndex = value),
                  ),
                ),
                Expanded(child: mainArea),
              ],
            );
          }
        },
      ),
    );
  }
}
