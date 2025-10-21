import 'dart:async';
import 'package:catch_this_ai/features/tracker/data/foreground/tracker_service.dart';
import 'package:catch_this_ai/features/tracker/data/local/tracker_local_storage.dart';
import 'package:catch_this_ai/features/tracker/domain/tracked_keyword.dart';
import 'package:flutter/material.dart';

/// ViewModel to manage tracking state and data
class TrackingViewModel extends ChangeNotifier {
  // local storage instance to persist tracked keywords
  final TrackerLocalStorage _localStorage;
  // tracker service singleton to manage audio streaming and keyword spotting
  final TrackerService _trackerService = TrackerService.instance;

  // Day check timer and tracking variables
  Timer? _dayCheckTimer;
  DateTime _currentDay = DateTime.now();

  // State variables
  final List<TrackedKeyword> _dayKeywordHistory = [];
  int _totalDayCount = 0;
  bool _isRunning = false;
  bool _isInitialized = false;

  // GlobalKey for AnimatedList in history view
  GlobalKey? historyListKey;

  // Getters for state variables for easy access
  List<TrackedKeyword> get dayKeywordHistory => _dayKeywordHistory;
  int get totalDayCount => _totalDayCount;
  bool get isRunning => _isRunning;
  bool get isInitialized => _isInitialized;

  TrackingViewModel(this._localStorage);

  // Initialize view model
  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize the local storage
    await _localStorage.init();

    // Load today's history to set initial state
    _loadTodayHistory();

    // Request necessary permissions then initialize the tracker service
    await _trackerService.requestPermissions();
    await _trackerService.init();

    // Register a callback to receive tracked keywords from the foreground task
    _trackerService.registerTrackedKeywordCallback(_onTrackedKeywordReceived);

    _isInitialized = true;
    notifyListeners();
  }

  // Start tracking process
  Future<void> start() async {
    if (_isRunning) return;

    // Start the tracker service
    await _trackerService.start();

    // Timer to check for day changes every minute
    _dayCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      if (!_isSameDay(now, _currentDay)) {
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

    await _trackerService.stop();
    _isRunning = false;
    _dayCheckTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _trackerService.dispose();
    _dayCheckTimer?.cancel();
    _isInitialized = false;
    super.dispose();
  }

  // Callback when a tracked keyword is received from the foreground task
  void _onTrackedKeywordReceived(TrackedKeyword trackedKeyword) {
    final now = DateTime.now();
    // Guard for the case when first keyword of the day is detected before the timer resets the day
    if (!_isSameDay(now, _currentDay)) {
      _loadTodayHistory();
    }

    _dayKeywordHistory.insert(0, trackedKeyword);
    final animatedList = historyListKey?.currentState as AnimatedListState?;
    animatedList?.insertItem(0);
    _totalDayCount++;

    // Save the tracked keyword to local storage
    _localStorage.addTrackedKeyword(trackedKeyword);

    notifyListeners();
  }

  // Helper to load today's history
  void _loadTodayHistory() {
    final today = DateTime.now();
    final todayHistory = _localStorage.getTrackedKeywordsDay(today);

    final animatedList = historyListKey?.currentState as AnimatedListState?;
    for (final keyword in todayHistory) {
      _dayKeywordHistory.insert(0, keyword);
      animatedList?.insertItem(0, duration: Duration(milliseconds: 1000));
    }

    _totalDayCount = _dayKeywordHistory.length;
    _currentDay = today;
  }

  // Helper to check if a two dates are on the same day
  bool _isSameDay(DateTime now, DateTime currentDay) {
    return now.year == currentDay.year &&
        now.month == currentDay.month &&
        now.day == currentDay.day;
  }
}
