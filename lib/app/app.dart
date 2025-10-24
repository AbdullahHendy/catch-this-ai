import 'package:catch_this_ai/core/data/tracking_repository.dart';
import 'package:catch_this_ai/core/services/foreground/tracking/tracking_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:catch_this_ai/features/daily_tracker/presentation/view_model/daily_tracker_view_model.dart';
import 'package:catch_this_ai/core/storage/db/tracking_local_storage.dart';
import 'package:catch_this_ai/app/home_page.dart';
import '../core/theme/app_theme.dart';

/// Main application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize data broker/repository dependencies (singleton instances)
    final localStorage = TrackingLocalStorage.instance;
    final trackingService = TrackingService.instance;
    // Create the data broker/repository
    final TrackingRepository trackingRepository = TrackingRepository(
      localStorage: localStorage,
      trackingService: trackingService,
    );

    return ChangeNotifierProvider(
      create: (_) => DailyTrackerViewModel(trackingRepository),
      builder: (context, child) {
        final viewModel = context.read<DailyTrackerViewModel>();

        // Run init and start tracking ONLY after the first frame when Flutter engine and isolate are ready
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await viewModel.init();
          await viewModel.start();
        });

        return MaterialApp(
          title: 'Catch This AI',
          theme: AppTheme.theme,
          initialRoute: '/',
          routes: {'/': (context) => const MyHomePage()},
        );
      },
    );
  }
}
