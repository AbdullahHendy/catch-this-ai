import 'dart:async';
import 'package:catch_this_ai/core/data/tracking_repository.dart';
import 'package:catch_this_ai/core/domain/tracked_keyword.dart';
import 'package:flutter/material.dart';
import 'package:catch_this_ai/core/utils/time_utils.dart';

/// ViewModel to manage stats state and data
class StatsViewModel extends ChangeNotifier {
  // instance of data broker/repository
  final TrackingRepository _repo;

  // Subscribe to the tracked keywords stream to be able to dispose it later
  StreamSubscription<TrackedKeyword>? _sub;

  // Timer to check for day, week, month changes
  Timer? _changeCheckTimer;
  DateTime _currentDay = DateTime.now();
  DateTime _currentWeek = DateTime.now();
  DateTime _currentMonth = DateTime.now();

  // State variables
  final List<TrackedKeyword> _dayKeywordHistory = [];
  final List<TrackedKeyword> _weekKeywordHistory = [];
  final List<TrackedKeyword> _monthKeywordHistory = [];
  int _totalDayCount = 0;
  int _totalWeekCount = 0;
  int _totalMonthCount = 0;

  int _totalLastDayCount = 0;
  int _totalLastWeekCount = 0;
  int _totalLastMonthCount = 0;

  int _dayChangePercentage = 0;
  int _weekChangePercentage = 0;
  int _monthChangePercentage = 0;

  int _chartTimeFrameIndex = 0;
  final List<String> _chartTimeFrames = ['7d', '30d'];

  Map<DateTime, List<TrackedKeyword>> _last7DaysKeywordsMap = {};
  Map<DateTime, List<TrackedKeyword>> _last30DaysKeywordsMap = {};
  Map<DateTime, int> _last7DaysCountsMap = {};
  Map<DateTime, int> _last30DaysCountsMap = {};

  bool _isRunning = false;

  // Getters for state variables for easy access
  List<TrackedKeyword> get dayKeywordHistory => _dayKeywordHistory;
  List<TrackedKeyword> get weekKeywordHistory => _weekKeywordHistory;
  List<TrackedKeyword> get monthKeywordHistory => _monthKeywordHistory;

  int get totalDayCount => _totalDayCount;
  int get totalWeekCount => _totalWeekCount;
  int get totalMonthCount => _totalMonthCount;

  int get dayChangePercentage => _dayChangePercentage;
  int get weekChangePercentage => _weekChangePercentage;
  int get monthChangePercentage => _monthChangePercentage;

  int get chartTimeFrameIndex => _chartTimeFrameIndex;
  List<String> get chartTimeFrames => _chartTimeFrames;

  Map<DateTime, List<TrackedKeyword>> get last7DaysKeywordsMap =>
      _last7DaysKeywordsMap;
  Map<DateTime, List<TrackedKeyword>> get last30DaysKeywordsMap =>
      _last30DaysKeywordsMap;

  Map<DateTime, int> get last7DaysCountsMap => _last7DaysCountsMap;
  Map<DateTime, int> get last30DaysCountsMap => _last30DaysCountsMap;

  bool get isRunning => _isRunning;

  StatsViewModel(this._repo);

  // Start listening for tracked keywords
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    // Load initial values
    _init();
    notifyListeners();

    // Subscribe to the tracked keywords stream
    _sub = _repo.stream.listen((trackedKeyword) {
      _onTrackedKeywordReceived(trackedKeyword);
    });

    // Timer to check for changes every minute
    // TODO: Consider looking into one shot timers that calculate the exact duration
    // until the next day/week/month change to optimize this further
    _changeCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      if (!isSameDay(now, _currentDay)) {
        // Day has changed, states
        _onDayChanged();
        notifyListeners();
      }

      if (!isSameWeek(now, _currentWeek)) {
        // Week has changed, reload states
        _onWeekChanged();
        notifyListeners();
      }

      if (!isSameMonth(now, _currentMonth)) {
        // Month has changed, reload states
        _onMonthChanged();
        notifyListeners();
      }
    });
  }

  Future<void> stop() async {
    if (!_isRunning) return;

    await _sub?.cancel();
    _isRunning = false;
    _changeCheckTimer?.cancel();
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _changeCheckTimer?.cancel();
    _isRunning = false;
    super.dispose();
  }

  // Callback when a tracked keyword is received from the foreground task
  Future<void> _onTrackedKeywordReceived(TrackedKeyword trackedKeyword) async {
    final now = DateTime.now();
    // Guard for the cases when first keyword of the day/week/month is detected
    // before the timer resets the day/week/month.
    // This is fine because when the timer ticks next, it will reload the histories again,
    // which will have the updated keywords.
    if (!isSameDay(now, _currentDay)) {
      _onDayChanged();
    }

    if (!isSameWeek(now, _currentWeek)) {
      _onWeekChanged();
    }

    if (!isSameMonth(now, _currentMonth)) {
      _onMonthChanged();
    }

    _dayKeywordHistory.insert(0, trackedKeyword);
    _weekKeywordHistory.insert(0, trackedKeyword);
    _monthKeywordHistory.insert(0, trackedKeyword);
    _totalDayCount++;
    _totalWeekCount++;
    _totalMonthCount++;

    // Recalculate percentage changes
    _percentChanges();

    // Update last 7 and 30 days keywords maps and counts maps
    _updateLastDaysKeywordsMaps();
    _updateLastDaysKeywordsCountsMaps();

    notifyListeners();
  }

  // Helpers to load history
  void _loadDayHistory() {
    final today = DateTime.now();
    final todayHistory = _repo.getDayKeywords(today);

    // Clear and reload the day's history
    _dayKeywordHistory
      ..clear()
      ..addAll(todayHistory.reversed);

    _totalDayCount = _dayKeywordHistory.length;
    _currentDay = today;
  }

  void _loadWeekHistory() {
    final today = DateTime.now();
    final weekHistory = _repo.getWeekKeywords(today);

    // Clear and reload the week's history
    _weekKeywordHistory
      ..clear()
      ..addAll(weekHistory.reversed);

    _totalWeekCount = _weekKeywordHistory.length;
    _currentWeek = today;
  }

  void _loadMonthHistory() {
    final today = DateTime.now();
    final monthHistory = _repo.getMonthKeywords(today);

    // Clear and reload the month's history
    _monthKeywordHistory
      ..clear()
      ..addAll(monthHistory.reversed);

    _totalMonthCount = _monthKeywordHistory.length;
    _currentMonth = today;
  }

  void _loadHistory() {
    _loadDayHistory();
    _loadWeekHistory();
    _loadMonthHistory();
  }

  // Helper to load last period histories counts
  void _loadLastDayHistoryCount() {
    final yesterday = _currentDay.subtract(const Duration(days: 1));
    final yesterdayHistory = _repo.getDayKeywords(yesterday);

    _totalLastDayCount = yesterdayHistory.length;
  }

  void _loadLastWeekHistoryCount() {
    final lastWeekDay = _currentWeek.subtract(const Duration(days: 7));
    final lastWeekHistory = _repo.getWeekKeywords(lastWeekDay);

    _totalLastWeekCount = lastWeekHistory.length;
  }

  void _loadLastMonthHistoryCount() {
    final lastMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    final lastMonthHistory = _repo.getMonthKeywords(lastMonth);

    _totalLastMonthCount = lastMonthHistory.length;
  }

  void _loadLastHistoryCounts() {
    _loadLastDayHistoryCount();
    _loadLastWeekHistoryCount();
    _loadLastMonthHistoryCount();
  }

  // Helpers to calculate day/week/month percentage change
  void _dayPercentChange() {
    if (_totalLastDayCount == 0) {
      _dayChangePercentage = _totalDayCount == 0 ? 0 : 100;
    } else {
      _dayChangePercentage =
          ((_totalDayCount - _totalLastDayCount) / _totalLastDayCount * 100)
              .round();
    }
  }

  void _weekPercentChange() {
    if (_totalLastWeekCount == 0) {
      _weekChangePercentage = _totalWeekCount == 0 ? 0 : 100;
    } else {
      _weekChangePercentage =
          ((_totalWeekCount - _totalLastWeekCount) / _totalLastWeekCount * 100)
              .round();
    }
  }

  void _monthPercentChange() {
    if (_totalLastMonthCount == 0) {
      _monthChangePercentage = _totalMonthCount == 0 ? 0 : 100;
    } else {
      _monthChangePercentage =
          ((_totalMonthCount - _totalLastMonthCount) /
                  _totalLastMonthCount *
                  100)
              .round();
    }
  }

  void _percentChanges() {
    _dayPercentChange();
    _weekPercentChange();
    _monthPercentChange();
  }

  // Helpers for updating last7DaysKeywordsMap and last30DaysKeywordsMap
  void _updateLastDaysKeywordsMaps() {
    _last7DaysKeywordsMap = _repo.getLastDaysKeywordsMap(7);
    _last30DaysKeywordsMap = _repo.getLastDaysKeywordsMap(30);
  }

  void _updateLastDaysKeywordsCountsMaps() {
    _last7DaysCountsMap = _last7DaysKeywordsMap.map(
      (day, keywords) => MapEntry(day, keywords.length),
    );

    _last30DaysCountsMap = _last30DaysKeywordsMap.map(
      (day, keywords) => MapEntry(day, keywords.length),
    );
  }

  // Helpers for things to do when day/week/month changes
  void _onDayChanged() {
    _loadDayHistory();
    _loadLastDayHistoryCount();
    _dayPercentChange();
    _updateLastDaysKeywordsMaps();
    _updateLastDaysKeywordsCountsMaps();
  }

  void _onWeekChanged() {
    _loadWeekHistory();
    _loadLastWeekHistoryCount();
    _weekPercentChange();
    _updateLastDaysKeywordsMaps();
    _updateLastDaysKeywordsCountsMaps();
  }

  void _onMonthChanged() {
    _loadMonthHistory();
    _loadLastMonthHistoryCount();
    _monthPercentChange();
    _updateLastDaysKeywordsMaps();
    _updateLastDaysKeywordsCountsMaps();
  }

  // Helper to initialize all states
  void _init() {
    // Load histories to update initial states
    _loadHistory();
    _loadLastHistoryCounts();

    // Calculate initial percentage changes
    _percentChanges();

    // Load last 7 and 30 days keywords maps and count maps for charts
    _updateLastDaysKeywordsMaps();
    _updateLastDaysKeywordsCountsMaps();
  }

  // Chart-related functions
  // Set the chart time frame index (0 for 7d, 1 for 30d)
  void setChartTimeFrameIndex(int index) {
    if (index == _chartTimeFrameIndex) return;
    _chartTimeFrameIndex = index;
    notifyListeners();
  }

  // Returns the selected days counts map based on the current chart time frame index
  Map<DateTime, int> get selectedDaysCountsMap =>
      _chartTimeFrameIndex == 0 ? _last7DaysCountsMap : _last30DaysCountsMap;

  // Returns the maximum Y value for the chart
  double get chartMaxY {
    if (selectedDaysCountsMap.isEmpty) return 5.0;
    return selectedDaysCountsMap.values
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
  }
}
