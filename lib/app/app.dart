import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:catch_this_ai/app/home_page.dart';
import 'package:catch_this_ai/core/data/tracking_repository.dart';
import 'package:catch_this_ai/core/services/foreground/tracking/tracking_service.dart';
import 'package:catch_this_ai/core/storage/db/tracking_local_storage.dart';
import 'package:catch_this_ai/core/storage/db/db_manager.dart';
import 'package:catch_this_ai/features/daily_tracker/presentation/view_model/daily_tracker_view_model.dart';
import '../core/theme/app_theme.dart';

/// Main application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Ensure Hive (DBManager) is ready before anything else runs
      // Might not be exactly needed since Hive initialization is fast and there is no heavy data loading etc.
      // Kept for good practice and possible future proofing
      future: DBManager.instance.init(),
      builder: (context, snapshot) {
        // Circular progress indicator while waiting for DBManager init
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        // Initialize the tracking data broker/repository dependencies
        final trackingService = TrackingService.instance;
        final trackingLocalStorage = TrackingLocalStorage(DBManager.instance);

        // Create the tracking data broker/repository
        final trackingRepository = TrackingRepository(
          localStorage: trackingLocalStorage,
          trackingService: trackingService,
        );

        return ChangeNotifierProvider(
          create: (_) => DailyTrackerViewModel(trackingRepository),
          builder: (context, _) {
            final trackingViewModel = context.read<DailyTrackerViewModel>();

            // Run init and start tracking ONLY after the first frame when Flutter engine and isolate are ready
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await trackingViewModel.init();
              await trackingViewModel.start();
            });

            return MaterialApp(
              title: 'Catch This AI',
              theme: AppTheme.theme,
              initialRoute: '/',
              routes: {'/': (context) => const MyHomePage()},
            );
          },
        );
      },
    );
  }
}
