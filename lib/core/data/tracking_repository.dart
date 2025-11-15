import 'dart:async';
import 'package:catch_this_ai/core/domain/tracked_text.dart';
import 'package:catch_this_ai/core/services/foreground/tracking/tracking_service.dart';
import 'package:catch_this_ai/core/storage/db/settings_local_storage.dart';
import 'package:catch_this_ai/core/storage/db/tracking_local_storage.dart';
import 'package:flutter/foundation.dart';

/// Repository that connects the Foreground TrackingService and the local database.
///   * Listens to tracked texts coming from the foreground task
///   * Persists them into the local storage
///   * Streams new tracked texts to listeners (e.g. features ViewModels)
///   * Manages settings related to tracking
class TrackingRepository {
  // Dependencies: local storages and tracking service
  final TrackingLocalStorage _trackingLocalStorage;
  final SettingsLocalStorage _settingsLocalStorage;
  final TrackingService _trackingService;

  // Stream controller to send TrackedText objects to listeners
  // Broadcast stream to allow possible multiple listeners to subscribe
  final _trackedTextController = StreamController<TrackedText>.broadcast();

  // Stream controller to send 'clear' signals to listeners indicating that it's clearing tracking data
  final _clearController = StreamController<void>.broadcast();

  // Getter for the tracked text stream to allow listeners to subscribe and do something like:
  // trackingRepository.stream.listen((trackedText) { ... });
  Stream<TrackedText> get trackedTextStream => _trackedTextController.stream;

  // Getter for the clear signal stream to allow listeners to subscribe and do something like:
  // trackingRepository.clearStream.listen((_) { ... });
  Stream<void> get clearStream => _clearController.stream;

  // Cached TrackedTexts from the local storage
  // TODO: think about maybe only caching texts for a limited time period if memory becomes an issue
  List<TrackedText> _cachedTexts = [];

  // Map of DateTime to List<TrackedText> to group texts by day/week/month
  // This is useful when dealing with running window of time periods
  Map<DateTime, List<TrackedText>> _textsByLocalDayMap = {};

  bool _isInitialized = false;

  TrackingRepository({
    required TrackingLocalStorage trackingLocalStorage,
    required SettingsLocalStorage settingsLocalStorage,
    required TrackingService trackingService,
  }) : _trackingLocalStorage = trackingLocalStorage,
       _settingsLocalStorage = settingsLocalStorage,
       _trackingService = trackingService;

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize local storages
    await _settingsLocalStorage.init();
    await _trackingLocalStorage.init();

    // Request necessary permissions then initialize the tracking service
    await _trackingService.requestPermissions();
    await _trackingService.init();

    // Register callback for tracked texts from foreground service
    _trackingService.registerTrackedTextCallback(_onTrackedTextReceived);

    // Load texts from local storage into cache (UTC)
    _cachedTexts = _trackingLocalStorage.getAllTrackedTexts();

    // Group cached texts by day for easier querying later
    _textsByLocalDayMap = _groupTextsByLocalDay(_cachedTexts);

    _isInitialized = true;
  }

  // Start foreground tracking service
  Future<void> start() async {
    // Get the saved speech service type from settings storage
    final speechServiceType = _settingsLocalStorage.getSpeechServiceType();
    await _trackingService.start(speechServiceType);
  }

  // Stop foreground tracking service
  Future<void> stop() async {
    await _trackingService.stop();
  }

  // Dispose the repository (close streams, cleanup service)
  Future<void> dispose() async {
    await _trackingService.dispose();
    await _trackedTextController.close();
    await _clearController.close();
    _cachedTexts.clear();
    _textsByLocalDayMap.clear();
    _isInitialized = false;
  }

  // ------------- Main Tracking -------------

  // All getLocalXTexts method return a list of TrackedText objects within the requested local time period,
  // but the text timestamps are still in UTC for consistency.

  // Query cached texts (UTC) for a specific day (Local) from local storage
  List<TrackedText> getLocalDayTexts(DateTime localDay) {
    final startOfDayLocal = DateTime(
      localDay.year,
      localDay.month,
      localDay.day,
    );
    final startOfNextDayLocal = startOfDayLocal.add(const Duration(days: 1));
    final startOfDay = startOfDayLocal.toUtc();
    final startOfNextDay = startOfNextDayLocal.toUtc();

    return _cachedTexts
        .where(
          (text) =>
              // Not before start of day to make it inclusive
              !text.timestamp.isBefore(startOfDay) &&
              // Before the next day to make it exclusive of the next day
              text.timestamp.isBefore(startOfNextDay),
        )
        .toList();
  }

  // Query cached texts (UTC) for a specific week (Local) from local storage
  // Week is considered to start from Monday to Sunday
  List<TrackedText> getLocalWeekTexts(DateTime localDay) {
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

    final weekTexts = _cachedTexts
        .where(
          (text) =>
              // Not before start of week to make it inclusive
              !text.timestamp.isBefore(startOfWeek) &&
              // Before the next monday to make it inclusive of the last day (sunday)
              text.timestamp.isBefore(startOfNextWeek),
        )
        .toList();

    return weekTexts;
  }

  // Query cached texts (UTC) for a specific month (Local) from local storage
  List<TrackedText> getLocalMonthTexts(DateTime localMonth) {
    final startOfMonthLocal = DateTime(localMonth.year, localMonth.month, 1);
    // Account for year change
    final startOfNextMonthLocal = (localMonth.month == 12)
        ? DateTime(localMonth.year + 1, 1, 1)
        : DateTime(localMonth.year, localMonth.month + 1, 1);

    final startOfMonth = startOfMonthLocal.toUtc();
    final startOfNextMonth = startOfNextMonthLocal.toUtc();
    return _cachedTexts
        .where(
          (text) =>
              !text.timestamp.isBefore(startOfMonth) &&
              text.timestamp.isBefore(startOfNextMonth),
        )
        .toList();
  }

  // Callback when the foreground isolate sends a new tracked text (in UTC)
  Future<void> _onTrackedTextReceived(TrackedText textUTC) async {
    // Prevent duplicates: check if the text with the same timestamp already exists
    // Although rare, it can happen on quick/hot restarts of the foreground service
    // Foreground service may resend the last tracked text on restart
    // This was observed during testing (running hot reload multiple times fast)
    // TODO: should probably identify root cause, see if a big problem during normal usage
    if (_cachedTexts.any(
      (ck) =>
          ck.timestamp == textUTC.timestamp &&
          listEquals(ck.keywords, textUTC.keywords) &&
          ck.text == textUTC.text,
    )) {
      return;
    }

    // Persist the text into local storage and broadcast it through the stream to listeners
    await _trackingLocalStorage.addTrackedText(textUTC);

    // Update cached texts
    _cachedTexts.add(textUTC);

    // Update texts by local day map
    final localTimestamp = textUTC.timestamp.toLocal();
    final localDayKey = DateTime(
      localTimestamp.year,
      localTimestamp.month,
      localTimestamp.day,
    );
    _textsByLocalDayMap.putIfAbsent(localDayKey, () => []).add(textUTC);

    // Broadcast the new text
    _trackedTextController.add(textUTC);
  }

  // Group cached texts by day
  Map<DateTime, List<TrackedText>> _groupTextsByLocalDay(
    List<TrackedText> textsUTC,
  ) {
    final Map<DateTime, List<TrackedText>> groupedLocal = {};

    for (final text in textsUTC) {
      final localTimestamp = text.timestamp.toLocal();
      final localDay = DateTime(
        localTimestamp.year,
        localTimestamp.month,
        localTimestamp.day,
      );

      groupedLocal.putIfAbsent(localDay, () => []).add(text);
    }

    return groupedLocal;
  }

  // Get map of most recent local n days and their tracked texts starting from a local reference day
  // Padding option to fill with empty lists for days with no texts
  // Without padding, function returns recent n days that have texts only (not necessarily the actual last n days)
  Map<DateTime, List<TrackedText>> getRecentLocalDaysTextsMap(
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
    final filteredEntries = _textsByLocalDayMap.entries
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
      final expectedDays = List<DateTime>.generate(n, (i) {
        final day = refLocalDayKey.subtract(Duration(days: n - 1 - i));
        // Normalize to midnight local time in case of misalignment e.g. daylight saving time changes
        return DateTime(day.year, day.month, day.day);
      });

      // Ensure all expected days are present in the result map
      for (var day in expectedDays) {
        result.putIfAbsent(day, () => []);
      }

      // Ensure the result map is sorted by DateTime key after padding
      final sortedKeys = result.keys.toList()..sort();
      final paddedResult = Map.fromEntries(
        sortedKeys.map((key) => MapEntry(key, result[key]!)),
      );

      // After padding, take the last n entries again in case padding added extra days
      final paddedResultN = Map.fromEntries(
        paddedResult.entries.toList().reversed.take(n).toList().reversed,
      );

      return paddedResultN;
    }

    return result;
  }

  // ------------- Settings -------------

  // Switch speech service type
  Future<void> switchSpeechServiceType(String newServiceType) async {
    // Save the new speech service type to settings storage
    await _settingsLocalStorage.setSpeechServiceType(newServiceType);

    await _trackingService.switchSpeechServiceType(newServiceType);
  }

  // Get current speech service type
  String getServiceType() {
    return _settingsLocalStorage.getSpeechServiceType();
  }

  // Set keywords only mode
  Future<void> setKeywordsOnlyMode(bool isEnabled) async {
    await _settingsLocalStorage.setKeywordsOnlyMode(isEnabled);
  }

  // Get keywords only mode
  bool getKeywordsOnlyMode() {
    return _settingsLocalStorage.getKeywordsOnlyMode();
  }

  // Set pad empty days in charts
  Future<void> setPadEmptyDaysInCharts(bool pad) async {
    await _settingsLocalStorage.setPadEmptyDaysInCharts(pad);
  }

  // Get pad empty days in charts
  bool getPadEmptyDaysInCharts() {
    return _settingsLocalStorage.getPadEmptyDaysInCharts();
  }

  // Clear all tracking data
  Future<void> clearTrackingData() async {
    await _trackingLocalStorage.clearTrackedTexts();
    // Also clear cached texts and grouped map
    _cachedTexts.clear();
    _textsByLocalDayMap.clear();
    // Notify listeners about the clear action
    _clearController.add(null);
  }

  // Clear all settings
  Future<void> clearSettings() async {
    await _settingsLocalStorage.clearSettings();
  }
}
