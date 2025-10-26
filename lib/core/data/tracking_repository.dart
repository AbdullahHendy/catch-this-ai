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

  // Map of DateTime to List<TrackedKeyword> to group keywords by day/week/month
  // This is useful when dealing with running window of time periods
  Map<DateTime, List<TrackedKeyword>> _keywordsByDayMap = {};

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

    // Group cached keywords by day for easier querying later
    _keywordsByDayMap = _groupKeywordsByDay(_cachedKeywords);

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
    _cachedKeywords.clear();
    _keywordsByDayMap.clear();
    _isInitialized = false;
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
    // Get start of the day to exactly find the beginning of the week
    final startOfDay = DateTime(day.year, day.month, day.day);

    final startOfWeek = startOfDay.subtract(
      Duration(days: startOfDay.weekday - DateTime.monday),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 7)); // Next Monday

    final weekKeywords = _cachedKeywords
        .where(
          (keyword) =>
              // Not before start of week to make it inclusive
              !keyword.timestamp.isBefore(startOfWeek) &&
              // Before the next monday to make it inclusive of the last day (sunday)
              keyword.timestamp.isBefore(endOfWeek),
        )
        .toList();

    return weekKeywords;
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

  // Callback when the foreground isolate sends a new tracked keyword
  Future<void> _onTrackedKeywordReceived(TrackedKeyword keyword) async {
    // Prevent duplicates: check if the keyword with the same timestamp already exists
    // Although rare, it can happen on quick/hot restarts of the foreground service
    // Foreground service may resend the last tracked keyword on restart
    // This was observed during testing (running hot reload multiple times fast)
    // TODO: should probably identify root cause, see if a big problem during normal usage
    if (_cachedKeywords.any(
      (ck) =>
          ck.timestamp == keyword.timestamp && ck.keyword == keyword.keyword,
    )) {
      return;
    }

    // Persist the keyword into local storage and broadcast it through the stream to listeners
    await _localStorage.addTrackedKeyword(keyword);
    // Update cached keywords
    _cachedKeywords.add(keyword);
    // Update keywords by day map
    final dayKey = DateTime(
      keyword.timestamp.year,
      keyword.timestamp.month,
      keyword.timestamp.day,
    );
    _keywordsByDayMap.putIfAbsent(dayKey, () => []).add(keyword);
    // Broadcast the new keyword
    _controller.add(keyword);
  }

  // Group cached keywords by day
  Map<DateTime, List<TrackedKeyword>> _groupKeywordsByDay(
    List<TrackedKeyword> keywords,
  ) {
    final Map<DateTime, List<TrackedKeyword>> grouped = {};

    for (final keyword in keywords) {
      final day = DateTime(
        keyword.timestamp.year,
        keyword.timestamp.month,
        keyword.timestamp.day,
      );

      grouped.putIfAbsent(day, () => []).add(keyword);
    }

    return grouped;
  }

  // Get map of most recent n days and their tracked keywords
  Map<DateTime, List<TrackedKeyword>> getLastDaysKeywordsMap(int n) {
    // See: https://stackoverflow.com/questions/65398100/how-can-i-grab-the-last-n-elements-in-a-mapint-dynamic

    // First sort the entries by DateTime key, Map guarantees insertion order but we still need to sort
    // in case entries were added out of order from DB when caching in init()
    final sortedEntries = _keywordsByDayMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Map.fromEntries(sortedEntries.reversed.take(n).toList().reversed);
  }
}
