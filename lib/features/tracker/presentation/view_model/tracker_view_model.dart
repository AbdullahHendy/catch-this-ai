import 'dart:async';
import 'package:catch_this_ai/features/tracker/data/local/tracker_local_storage.dart';
import 'package:catch_this_ai/features/tracker/data/tracker_repository.dart';
import 'package:catch_this_ai/features/tracker/domain/tracked_keyword.dart';
import 'package:flutter/material.dart';

/// ViewModel to manage tracking state and data
class TrackingViewModel extends ChangeNotifier {
  // repository instance to handle tracking logic (audio service + kws service)
  final TrackerRepository _repository;
  // local storage instance to persist tracked keywords
  final TrackerLocalStorage _localStorage;

  // Subscription to have a handle to stop listening to tracked keywords later
  StreamSubscription<TrackedKeyword>? _trackWordSub;

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

  TrackingViewModel(this._repository, this._localStorage);

  // Initialize view model
  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize the local storage
    await _localStorage.init();

    // Initialize the repository and its services
    await _repository.init();

    // Load today's history to set initial state
    _loadTodayHistory();

    _isInitialized = true;
    notifyListeners();
  }

  // Start tracking process
  Future<void> start() async {
    if (_isRunning) return;

    // Start the tracking process in the repository (audio service + kws service)
    await _repository.start();

    // Listen to tracked keywords (TrackedKeyword) from the repository stream
    _trackWordSub = _repository.stream.listen((trackedKeyword) {
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

      // Notify listeners (UI) about state changes
      notifyListeners();
    });

    // Timer to check for day changes every minute
    _dayCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      if (!_isSameDay(now, _currentDay)) {
        // Day has changed, reload today's history (updates _currentDay as well)
        _loadTodayHistory();
      }
    });

    _isRunning = true;
    // Notify listeners that _isRunning was set (Not sure if needed here)
    notifyListeners();
  }

  Future<void> stop() async {
    if (!_isRunning) return;

    await _repository.stop();
    await _trackWordSub?.cancel();
    _isRunning = false;
    _dayCheckTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _trackWordSub?.cancel();
    _dayCheckTimer?.cancel();
    _isInitialized = false;
    super.dispose();
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
