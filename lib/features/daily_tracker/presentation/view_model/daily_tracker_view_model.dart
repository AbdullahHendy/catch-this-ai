import 'dart:async';
import 'package:catch_this_ai/core/data/tracking_repository.dart';
import 'package:catch_this_ai/core/domain/tracked_text.dart';
import 'package:catch_this_ai/core/utils/time_utils.dart';
import 'package:flutter/material.dart';

/// ViewModel to manage tracking state and data
class DailyTrackerViewModel extends ChangeNotifier {
  // instance of data broker/repository
  final TrackingRepository _repo;

  // Subscribe to the tracked texts stream to be able to dispose it later
  StreamSubscription<TrackedText>? _trackedTextSub;

  // Subscription to the clear stream to handle data clearing
  StreamSubscription<void>? _clearSub;

  // Day check timer and tracking variables
  Timer? _dayCheckTimer;
  DateTime _currentDay = DateTime.now();

  // State variables
  final List<TrackedText> _dayTextHistory = [];
  int _totalDayCount = 0;
  bool _isRunning = false;

  // GlobalKey for AnimatedList in history view
  GlobalKey? historyListKey;

  // Getters for state variables for easy access
  List<TrackedText> get dayTextHistory => _dayTextHistory;
  int get totalDayCount => _totalDayCount;
  bool get isRunning => _isRunning;

  DailyTrackerViewModel(this._repo);

  // Start listening for tracked texts
  Future<void> start() async {
    if (_isRunning) return;

    // Load today's history to set initial states
    _loadTodayHistory();
    notifyListeners();

    // Subscribe to the tracked texts stream
    _trackedTextSub = _repo.trackedTextStream.listen((trackedTextUTC) {
      _onTrackedTextReceived(trackedTextUTC);
    });

    // Subscribe to the clear stream to handle data clearing
    _clearSub = _repo.clearStream.listen((_) {
      // Received clear signal, means data has been cleared, just re-load everything
      _loadTodayHistory();
      notifyListeners();
    });

    // Timer to check for day changes every minute
    _dayCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      if (!isSameDay(now, _currentDay)) {
        // Day has changed, reload today's history (updates _currentDay as well)
        _loadTodayHistory();
        notifyListeners();
      }
    });

    _isRunning = true;
    // Notify listeners that _isRunning was set (Not sure if needed here)
    notifyListeners();
  }

  Future<void> stop() async {
    if (!_isRunning) return;

    await _trackedTextSub?.cancel();
    await _clearSub?.cancel();
    _isRunning = false;
    _dayCheckTimer?.cancel();
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await _trackedTextSub?.cancel();
    await _clearSub?.cancel();
    _dayCheckTimer?.cancel();
    _isRunning = false;
    super.dispose();
  }

  // Callback when a tracked text is received from the foreground task
  Future<void> _onTrackedTextReceived(TrackedText trackedTextUTC) async {
    final now = DateTime.now();
    // Guard for the case when first text of the day is detected before the timer resets the day
    if (!isSameDay(now, _currentDay)) {
      _loadTodayHistory();
    }

    // Create a local tracked text for history list
    final trackedTextLocal = TrackedText(
      trackedTextUTC.text,
      trackedTextUTC.keywords,
      trackedTextUTC.timestamp.toLocal(),
    );

    _dayTextHistory.insert(0, trackedTextLocal);
    final animatedList = historyListKey?.currentState as AnimatedListState?;
    animatedList?.insertItem(0);

    // Count total keywords for the text and add to total count
    _totalDayCount += trackedTextLocal.keywords.length;

    notifyListeners();
  }

  // Helper to load today's history
  void _loadTodayHistory() {
    final today = DateTime.now();
    // Get today's history from the repository (texts returned for the local day but text timestamps are in UTC)
    final todayHistory = _repo.getLocalDayTexts(today);

    // Clear and reload the day's history with animation
    _dayTextHistory.clear();

    final animatedList = historyListKey?.currentState as AnimatedListState?;
    for (final text in todayHistory) {
      final textLocal = TrackedText(
        text.text,
        text.keywords,
        text.timestamp.toLocal(),
      );
      _dayTextHistory.insert(0, textLocal);
      animatedList?.insertItem(0);
    }

    // _totalDayCount is the total number of keywords within each text for today
    _totalDayCount = todayHistory.fold<int>(
      0,
      (previousValue, text) => previousValue + text.keywords.length,
    );
    _currentDay = today;
  }
}
