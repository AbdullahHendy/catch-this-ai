import 'dart:async';
import 'package:catch_this_ai/core/domain/tracked_keyword.dart';
import 'package:catch_this_ai/core/services/foreground/tracking/tracking_service.dart';
import 'package:catch_this_ai/core/storage/db/tracking_local_storage.dart';

/// Repository that connects the Foreground TrackingService and the local database.
///   * Listens to tracked keywords coming from the foreground task
///   * Persists them into the local storage
///   * Streams new tracked keywords to listeners (e.g. features ViewModels)
class TrackingRepository {
  // Dependencies: local storage and tracking service
  final TrackingLocalStorage _localStorage;
  final TrackingService _trackingService;

  // Stream controller to send TrackedKeyword objects to listeners
  // Broadcast stream to allow possible multiple listeners to subscribe
  final _controller = StreamController<TrackedKeyword>.broadcast();

  // Getter for the tracked keywords stream to allow listeners to subscribe and do something like:
  // trackingRepository.stream.listen((trackedKeyword) { ... });
  Stream<TrackedKeyword> get stream => _controller.stream;

  // Cached TrackedKeywords from the local storage
  // TODO: think about maybe only caching keywords for a limited time period if memory becomes an issue
  List<TrackedKeyword> _cachedKeywords = [];

  bool _isInitialized = false;

  TrackingRepository({
    required TrackingLocalStorage localStorage,
    required TrackingService trackingService,
  }) : _localStorage = localStorage,
       _trackingService = trackingService;

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize local storage
    await _localStorage.init();

    // Request necessary permissions then initialize the tracking service
    await _trackingService.requestPermissions();
    await _trackingService.init();

    // Register callback for tracked keywords from foreground service
    _trackingService.registerTrackedKeywordCallback(_onTrackedKeywordReceived);

    // Load keywords from local storage into cache
    _cachedKeywords = _localStorage.getAllTrackedKeywords();

    _isInitialized = true;
  }

  // Start foreground tracking service
  Future<void> start() async {
    await _trackingService.start();
  }

  // Stop foreground tracking service
  Future<void> stop() async {
    await _trackingService.stop();
  }

  // Dispose the repository (close streams, cleanup service)
  Future<void> dispose() async {
    await _trackingService.dispose();
    await _controller.close();
    _isInitialized = false;
  }

  // Callback when the foreground isolate sends a new tracked keyword
  Future<void> _onTrackedKeywordReceived(TrackedKeyword keyword) async {
    // Persist the keyword into local storage and broadcast it through the stream to listeners
    await _localStorage.addTrackedKeyword(keyword);
    _cachedKeywords.add(keyword);
    _controller.add(keyword);
  }

  // Query cached keywords for a specific day from local storage
  List<TrackedKeyword> getDayKeywords(DateTime day) {
    return _cachedKeywords
        .where(
          (keyword) =>
              keyword.timestamp.year == day.year &&
              keyword.timestamp.month == day.month &&
              keyword.timestamp.day == day.day,
        )
        .toList();
  }

  // Query cached keywords for a specific week from local storage
  // Week is considered to start from Monday to Sunday
  List<TrackedKeyword> getWeekKeywords(DateTime day) {
    final startOfWeek = day.subtract(
      Duration(days: day.weekday - DateTime.monday),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 7)); // Next Monday
    return _cachedKeywords
        .where(
          (keyword) =>
              // Not before start of week to make it inclusive
              !keyword.timestamp.isBefore(startOfWeek) &&
              // Before the next monday to make it inclusive of the last day (sunday)
              keyword.timestamp.isBefore(endOfWeek),
        )
        .toList();
  }

  // Query cached keywords for a specific month from local storage
  List<TrackedKeyword> getMonthKeywords(DateTime month) {
    return _cachedKeywords
        .where(
          (keyword) =>
              keyword.timestamp.year == month.year &&
              keyword.timestamp.month == month.month,
        )
        .toList();
  }
}
