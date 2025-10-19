import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:catch_this_ai/features/tracker/presentation/view_model/tracker_view_model.dart';
import 'package:catch_this_ai/features/tracker/data/tracker_repository.dart';
import 'package:catch_this_ai/core/audio/audio_stream_service.dart';
import 'package:catch_this_ai/core/kws/sherpa_kws_service.dart';
import 'package:catch_this_ai/app/home_page.dart';
import '../core/theme/app_theme.dart';

/// Main application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate audio, KWS services, and tracker repository
    final audioService = AudioStreamService();
    final kwsService = SherpaKwsService();
    final trackerRepository = TrackerRepository(audioService, kwsService);

    return ChangeNotifierProvider(
      create: (_) => TrackingViewModel(trackerRepository)..start(),
      child: MaterialApp(
        title: 'Catch This AI',
        theme: AppTheme.theme,
        home: const MyHomePage(),
      ),
    );
  }
}
