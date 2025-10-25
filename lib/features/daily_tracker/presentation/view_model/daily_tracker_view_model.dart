import 'dart:async';
import 'package:catch_this_ai/core/data/tracking_repository.dart';
import 'package:catch_this_ai/core/domain/tracked_keyword.dart';
import 'package:catch_this_ai/core/utils/time_utils.dart';
import 'package:flutter/material.dart';

/// ViewModel to manage tracking state and data
class DailyTrackerViewModel extends ChangeNotifier {
  // instance of data broker/repository
  final TrackingRepository _repo;

  // Subscribe to the tracked keywords stream to be able to dispose it later
  StreamSubscription<TrackedKeyword>? _sub;

  // Day check timer and tracking variables
  Timer? _dayCheckTimer;
  DateTime _currentDay = DateTime.now();

  // State variables
  final List<TrackedKeyword> _dayKeywordHistory = [];
  int _totalDayCount = 0;
  bool _isRunning = false;

  // GlobalKey for AnimatedList in history view
  GlobalKey? historyListKey;

  // Getters for state variables for easy access
  List<TrackedKeyword> get dayKeywordHistory => _dayKeywordHistory;
  int get totalDayCount => _totalDayCount;
  bool get isRunning => _isRunning;

  DailyTrackerViewModel(this._repo);

  // Start listening for tracked keywords
  Future<void> start() async {
    if (_isRunning) return;

    // Load today's history to set initial states
    _loadTodayHistory();
    notifyListeners();

    // Subscribe to the tracked keywords stream
    _sub = _repo.stream.listen((trackedKeyword) {
      _onTrackedKeywordReceived(trackedKeyword);
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

    await _sub?.cancel();
    _isRunning = false;
    _dayCheckTimer?.cancel();
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _dayCheckTimer?.cancel();
    _isRunning = false;
    super.dispose();
  }

  // Callback when a tracked keyword is received from the foreground task
  Future<void> _onTrackedKeywordReceived(TrackedKeyword trackedKeyword) async {
    final now = DateTime.now();
    // Guard for the case when first keyword of the day is detected before the timer resets the day
    if (!isSameDay(now, _currentDay)) {
      _loadTodayHistory();
    }

    _dayKeywordHistory.insert(0, trackedKeyword);
    final animatedList = historyListKey?.currentState as AnimatedListState?;
    animatedList?.insertItem(0);
    _totalDayCount++;

    notifyListeners();
  }

  // Helper to load today's history
  void _loadTodayHistory() {
    final today = DateTime.now();
    final todayHistory = _repo.getDayKeywords(today);

    // Clear and reload the day's history with animation
    _dayKeywordHistory.clear();

    final animatedList = historyListKey?.currentState as AnimatedListState?;
    for (final keyword in todayHistory) {
      _dayKeywordHistory.insert(0, keyword);
      animatedList?.insertItem(0);
    }

    _totalDayCount = _dayKeywordHistory.length;
    _currentDay = today;
  }
}
