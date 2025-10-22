import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:catch_this_ai/features/tracker/presentation/view_model/tracker_view_model.dart';
import 'package:catch_this_ai/features/tracker/data/local/tracker_local_storage.dart';
import 'package:catch_this_ai/app/home_page.dart';
import '../core/theme/app_theme.dart';

/// Main application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize local storage (DB)
    final localStorage = TrackerLocalStorage();

    return ChangeNotifierProvider(
      create: (_) => TrackingViewModel(localStorage),
      builder: (context, child) {
        final viewModel = context.read<TrackingViewModel>();

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
