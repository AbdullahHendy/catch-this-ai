import 'package:catch_this_ai/core/data/tracking_repository.dart';
import 'package:catch_this_ai/core/services/foreground/tracking/tracking_service.dart';
import 'package:catch_this_ai/core/storage/db/db_manager.dart';
import 'package:catch_this_ai/core/storage/db/tracking_local_storage.dart';
import 'package:flutter/material.dart';

/// Dependency injection setup for the app (contains all services/singletons/repositories initialization)
/// See: https://docs.flutter.dev/app-architecture/case-study/dependency-injection
/// This will be used with FutureBuilder in the main app widget to ensure
/// all dependencies are ready before the app runs

class AppDependencies {
  final TrackingRepository trackingRepository;

  AppDependencies({required this.trackingRepository});
}

class AppInitializer {
  static late AppDependencies _deps;

  static Future<AppDependencies> initialize() async {
    // Ensure Flutter bindings are initialized since MyApp uses FutureBuilder and async operations
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize the database manager
    await DBManager.instance.init();

    // Initialize the tracking repository dependencies
    final trackingService = TrackingService.instance;
    final trackingLocalStorage = TrackingLocalStorage(DBManager.instance);

    // Create the tracking data broker/repository
    final trackingRepository = TrackingRepository(
      localStorage: trackingLocalStorage,
      trackingService: trackingService,
    );

    // Initialize and start the repository
    await trackingRepository.init();
    await trackingRepository.start();

    _deps = AppDependencies(trackingRepository: trackingRepository);

    return _deps;
  }

  static Future<void> dispose() async {
    await _deps.trackingRepository.dispose();
  }
}
