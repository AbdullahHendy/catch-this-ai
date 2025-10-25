import 'package:catch_this_ai/app/di/app_initializer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:catch_this_ai/app/home_page.dart';
import 'package:catch_this_ai/features/daily_tracker/presentation/view_model/daily_tracker_view_model.dart';
import 'package:catch_this_ai/core/theme/app_theme.dart';

/// Main application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppDependencies>(
      // Ensure all dependencies are ready before anything else runs
      future: AppInitializer.initialize(),
      builder: (context, snapshot) {
        // Circular progress indicator while waiting for DBManager init
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        // Extract dependencies
        final deps = snapshot.data!;

        return MultiProvider(
          providers: [
            ChangeNotifierProvider<DailyTrackerViewModel>(
              create: (_) =>
                  DailyTrackerViewModel(deps.trackingRepository)..start(),
            ),
          ],

          child: MaterialApp(
            title: 'Catch This AI',
            theme: AppTheme.theme,
            initialRoute: '/',
            routes: {'/': (context) => const MyHomePage()},
          ),
        );
      },
    );
  }
}
