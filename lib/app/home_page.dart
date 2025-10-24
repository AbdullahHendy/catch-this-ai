import 'package:flutter/material.dart';
import 'package:catch_this_ai/features/daily_tracker/presentation/pages/daily_tracker_page.dart';

/// Home page with navigation to different sections
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
      0 => const DailyTrackerPage(),
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

    const Icon trackingIcon = Icon(Icons.spatial_tracking);
    const String trackingLabel = 'Catch This AI';
    const Icon statsIcon = Icon(Icons.query_stats);
    const String statsLabel = 'Stats';
    const Icon settingsIcon = Icon(Icons.settings);
    const String settingsLabel = 'Settings';

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
                        icon: trackingIcon,
                        label: trackingLabel,
                      ),
                      BottomNavigationBarItem(
                        icon: statsIcon,
                        label: statsLabel,
                      ),
                      BottomNavigationBarItem(
                        icon: settingsIcon,
                        label: settingsLabel,
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
                        icon: trackingIcon,
                        label: Text(trackingLabel),
                      ),
                      NavigationRailDestination(
                        icon: statsIcon,
                        label: Text(statsLabel),
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
