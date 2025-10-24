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
    _controller.add(keyword);
  }

  // Query tracked keywords for a specific day from DB
  List<TrackedKeyword> getDayKeywords(DateTime day) =>
      _localStorage.getTrackedKeywordsDay(day);

  // Query tracked keywords for a specific week from DB
  List<TrackedKeyword> getWeekKeywords(DateTime day) =>
      _localStorage.getTrackedKeywordsWeek(day);

  // Query tracked keywords for a specific month from DB
  List<TrackedKeyword> getMonthKeywords(DateTime month) =>
      _localStorage.getTrackedKeywordsMonth(month);
}
