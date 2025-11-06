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
  Map<DateTime, List<TrackedKeyword>> _keywordsByLocalDayMap = {};

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
    _keywordsByLocalDayMap = _groupKeywordsByLocalDay(_cachedKeywords);

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
    _keywordsByLocalDayMap.clear();
    _isInitialized = false;
  }

  // Query cached keywords (UTC) for a specific day (Local) from local storage
  List<TrackedKeyword> getLocalDayKeywords(DateTime localDay) {
    final startOfDayLocal = DateTime(
      localDay.year,
      localDay.month,
      localDay.day,
    );
    final startOfNextDayLocal = startOfDayLocal.add(const Duration(days: 1));
    final startOfDay = startOfDayLocal.toUtc();
    final startOfNextDay = startOfNextDayLocal.toUtc();

    return _cachedKeywords
        .where(
          (keyword) =>
              // Not before start of day to make it inclusive
              !keyword.timestamp.isBefore(startOfDay) &&
              // Before the next day to make it exclusive of the next day
              keyword.timestamp.isBefore(startOfNextDay),
        )
        .toList();
  }

  // Query cached keywords (UTC) for a specific week (Local) from local storage
  // Week is considered to start from Monday to Sunday
  List<TrackedKeyword> getLocalWeekKeywords(DateTime localDay) {
    // Get start of the day to exactly find the beginning of the week
    final startOfDayLocal = DateTime(
      localDay.year,
      localDay.month,
      localDay.day,
    );

    final startOfWeekLocal = startOfDayLocal.subtract(
      Duration(days: startOfDayLocal.weekday - DateTime.monday),
    );
    final startOfNextWeekLocal = startOfWeekLocal.add(
      const Duration(days: 7),
    ); // Next Monday
    final startOfWeek = startOfWeekLocal.toUtc();
    final startOfNextWeek = startOfNextWeekLocal.toUtc();

    final weekKeywords = _cachedKeywords
        .where(
          (keyword) =>
              // Not before start of week to make it inclusive
              !keyword.timestamp.isBefore(startOfWeek) &&
              // Before the next monday to make it inclusive of the last day (sunday)
              keyword.timestamp.isBefore(startOfNextWeek),
        )
        .toList();

    return weekKeywords;
  }

  // Query cached keywords (UTC) for a specific month (Local) from local storage
  List<TrackedKeyword> getLocalMonthKeywords(DateTime localMonth) {
    final startOfMonthLocal = DateTime(localMonth.year, localMonth.month, 1);
    // Account for year change
    final startOfNextMonthLocal = (localMonth.month == 12)
        ? DateTime(localMonth.year + 1, 1, 1)
        : DateTime(localMonth.year, localMonth.month + 1, 1);

    final startOfMonth = startOfMonthLocal.toUtc();
    final startOfNextMonth = startOfNextMonthLocal.toUtc();
    return _cachedKeywords
        .where(
          (keyword) =>
              !keyword.timestamp.isBefore(startOfMonth) &&
              keyword.timestamp.isBefore(startOfNextMonth),
        )
        .toList();
  }

  // Callback when the foreground isolate sends a new tracked keyword (in UTC)
  Future<void> _onTrackedKeywordReceived(TrackedKeyword keywordUTC) async {
    // Prevent duplicates: check if the keyword with the same timestamp already exists
    // Although rare, it can happen on quick/hot restarts of the foreground service
    // Foreground service may resend the last tracked keyword on restart
    // This was observed during testing (running hot reload multiple times fast)
    // TODO: should probably identify root cause, see if a big problem during normal usage
    if (_cachedKeywords.any(
      (ck) =>
          ck.timestamp == keywordUTC.timestamp &&
          ck.keyword == keywordUTC.keyword,
    )) {
      return;
    }

    // Persist the keyword into local storage and broadcast it through the stream to listeners
    await _localStorage.addTrackedKeyword(keywordUTC);

    // Update cached keywords
    _cachedKeywords.add(keywordUTC);

    // Update keywords by local day map
    final localTimestamp = keywordUTC.timestamp.toLocal();
    final localDayKey = DateTime(
      localTimestamp.year,
      localTimestamp.month,
      localTimestamp.day,
    );
    _keywordsByLocalDayMap.putIfAbsent(localDayKey, () => []).add(keywordUTC);

    // Broadcast the new keyword
    _controller.add(keywordUTC);
  }

  // Group cached keywords by day
  Map<DateTime, List<TrackedKeyword>> _groupKeywordsByLocalDay(
    List<TrackedKeyword> keywordsUTC,
  ) {
    final Map<DateTime, List<TrackedKeyword>> groupedLocal = {};

    for (final keyword in keywordsUTC) {
      final localTimestamp = keyword.timestamp.toLocal();
      final localDay = DateTime(
        localTimestamp.year,
        localTimestamp.month,
        localTimestamp.day,
      );

      groupedLocal.putIfAbsent(localDay, () => []).add(keyword);
    }

    return groupedLocal;
  }

  // Get map of most recent local n days and their tracked keywords starting from a local reference day
  // Padding option to fill with empty lists for days with no keywords
  // Without padding, function returns recent n days that have keywords only (not necessarily the actual last n days)
  Map<DateTime, List<TrackedKeyword>> getRecentLocalDaysKeywordsMap(
    DateTime referenceLocalDay,
    int n,
    bool padEmptyDays,
  ) {
    // See: https://stackoverflow.com/questions/65398100/how-can-i-grab-the-last-n-elements-in-a-mapint-dynamic

    // Get day
    final refLocalDayKey = DateTime(
      referenceLocalDay.year,
      referenceLocalDay.month,
      referenceLocalDay.day,
    );

    // Get all entries from the map that are on or before the reference day
    final filteredEntries = _keywordsByLocalDayMap.entries
        .where((entry) => !entry.key.isAfter(refLocalDayKey))
        .toList();

    // Sort the entries by DateTime key
    filteredEntries.sort((a, b) => a.key.compareTo(b.key));

    // Take the last n entries
    final result = Map.fromEntries(
      filteredEntries.reversed.take(n).toList().reversed,
    );

    if (padEmptyDays) {
      // Get a list of the expected n days ending at reference day
      final expectedDays = List<DateTime>.generate(
        n,
        (i) => refLocalDayKey.subtract(Duration(days: n - 1 - i)),
      );

      // Ensure all expected days are present in the result map
      for (var day in expectedDays) {
        result.putIfAbsent(day, () => []);
      }

      // Ensure the result map is sorted by DateTime key after padding
      final sortedKeys = result.keys.toList()..sort();
      final paddedResult = Map.fromEntries(
        sortedKeys.map((key) => MapEntry(key, result[key]!)),
      );
      return paddedResult;
    }

    return result;
  }
}
