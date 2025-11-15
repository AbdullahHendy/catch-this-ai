import 'dart:async';
import 'package:catch_this_ai/core/data/tracking_repository.dart';
import 'package:catch_this_ai/core/domain/tracked_text.dart';
import 'package:flutter/material.dart';
import 'package:catch_this_ai/core/utils/time_utils.dart';

// Enum for chart time frames
enum ChartTimeFrame {
  week, // 7d view
  month, // 30d view
}

extension ChartTimeFrameExtension on ChartTimeFrame {
  int get days {
    switch (this) {
      case ChartTimeFrame.week:
        return 7;
      case ChartTimeFrame.month:
        return 30;
    }
  }

  String get label {
    switch (this) {
      case ChartTimeFrame.week:
        return '7d';
      case ChartTimeFrame.month:
        return '30d';
    }
  }
}

/// ViewModel to manage stats state and data
class StatsViewModel extends ChangeNotifier {
  // instance of data broker/repository
  final TrackingRepository _repo;

  // Subscribe to the tracked texts stream to be able to dispose it later
  StreamSubscription<TrackedText>? _trackedTextSub;

  // Subscription to the clear stream to handle data clearing
  StreamSubscription<void>? _clearSub;

  // Timer to check for day, week, month changes
  Timer? _changeCheckTimer;
  DateTime _currentDay = DateTime.now();
  DateTime _currentWeek = DateTime.now();
  DateTime _currentMonth = DateTime.now();

  // State variables
  final List<TrackedText> _dayTextHistory = [];
  final List<TrackedText> _weekTextHistory = [];
  final List<TrackedText> _monthTextHistory = [];
  int _totalDayCount = 0;
  int _totalWeekCount = 0;
  int _totalMonthCount = 0;

  int _totalLastDayCount = 0;
  int _totalLastWeekCount = 0;
  int _totalLastMonthCount = 0;

  int _dayChangePercentage = 0;
  int _weekChangePercentage = 0;
  int _monthChangePercentage = 0;

  ChartTimeFrame _selectedChartTimeFrame = ChartTimeFrame.week;

  Map<DateTime, List<TrackedText>> _last7DaysTextsMap = {};
  Map<DateTime, List<TrackedText>> _last30DaysTextsMap = {};
  Map<DateTime, int> _last7DaysCountsMap = {};
  Map<DateTime, int> _last30DaysCountsMap = {};

  bool _isRunning = false;

  // Getters for state variables for easy access
  List<TrackedText> get dayTextHistory => _dayTextHistory;
  List<TrackedText> get weekTextHistory => _weekTextHistory;
  List<TrackedText> get monthTextHistory => _monthTextHistory;

  int get totalDayCount => _totalDayCount;
  int get totalWeekCount => _totalWeekCount;
  int get totalMonthCount => _totalMonthCount;

  int get dayChangePercentage => _dayChangePercentage;
  int get weekChangePercentage => _weekChangePercentage;
  int get monthChangePercentage => _monthChangePercentage;

  ChartTimeFrame get selectedChartTimeFrame => _selectedChartTimeFrame;
  List<ChartTimeFrame> get chartTimeFrames => ChartTimeFrame.values;

  Map<DateTime, List<TrackedText>> get last7DaysTextsMap => _last7DaysTextsMap;
  Map<DateTime, List<TrackedText>> get last30DaysTextsMap =>
      _last30DaysTextsMap;

  Map<DateTime, int> get last7DaysCountsMap => _last7DaysCountsMap;
  Map<DateTime, int> get last30DaysCountsMap => _last30DaysCountsMap;

  bool get isRunning => _isRunning;

  StatsViewModel(this._repo);

  // Start listening for tracked texts
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    // Load initial values
    _init();
    notifyListeners();

    // Subscribe to the tracked texts stream
    _trackedTextSub = _repo.trackedTextStream.listen((trackedTextUTC) {
      _onTrackedTextReceived(trackedTextUTC);
    });

    // Subscribe to the clear stream to handle data clearing
    _clearSub = _repo.clearStream.listen((_) {
      // Received clear signal, means data has been cleared, just re-load everything
      _init();
      notifyListeners();
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

    await _trackedTextSub?.cancel();
    await _clearSub?.cancel();
    _isRunning = false;
    _changeCheckTimer?.cancel();
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await _trackedTextSub?.cancel();
    await _clearSub?.cancel();
    _changeCheckTimer?.cancel();
    _isRunning = false;
    super.dispose();
  }

  // Callback when a tracked text is received from the foreground task
  Future<void> _onTrackedTextReceived(TrackedText trackedTextUTC) async {
    final now = DateTime.now();
    // Guard for the cases when first text of the day/week/month is detected
    // before the timer resets the day/week/month.
    // This is fine because when the timer ticks next, it will reload the histories again,
    // which will have the updated texts.
    if (!isSameDay(now, _currentDay)) {
      _onDayChanged();
    }

    if (!isSameWeek(now, _currentWeek)) {
      _onWeekChanged();
    }

    if (!isSameMonth(now, _currentMonth)) {
      _onMonthChanged();
    }

    // Create a local tracked text for history lists
    final trackedTextLocal = TrackedText(
      trackedTextUTC.text,
      trackedTextUTC.keywords,
      trackedTextUTC.timestamp.toLocal(),
    );
    _dayTextHistory.insert(0, trackedTextLocal);
    _weekTextHistory.insert(0, trackedTextLocal);
    _monthTextHistory.insert(0, trackedTextLocal);
    // Counts are the total number of keywords within each text
    _totalDayCount += trackedTextLocal.keywords.length;
    _totalWeekCount += trackedTextLocal.keywords.length;
    _totalMonthCount += trackedTextLocal.keywords.length;

    // Recalculate percentage changes
    _percentChanges();

    // Update last 7 and 30 days texts maps and counts maps
    // In _last7DaysTextsMap and _last30DaysTextsMap, replace the list for the day of the new text with the updated list (_dayTextHistory)
    // For the first detected text of the day, the day entry might not exist yet in the maps,
    // depending on whether padEmptyDays was used when loading the maps or not.
    // Maps' keys are DateTime objects representing exact days (year, month, day) without time component.

    // _lastXDaysTextsMap is grouped by local day keys
    final dayKey = DateTime(
      trackedTextLocal.timestamp.year,
      trackedTextLocal.timestamp.month,
      trackedTextLocal.timestamp.day,
    );
    _last7DaysTextsMap[dayKey] = List.from(_dayTextHistory);
    _last30DaysTextsMap[dayKey] = List.from(_dayTextHistory);

    // Counts are the length of keywords lists within each text for the day
    _last7DaysCountsMap[dayKey] = _dayTextHistory.fold<int>(
      0,
      (previousValue, text) => previousValue + text.keywords.length,
    );

    _last30DaysCountsMap[dayKey] = _dayTextHistory.fold<int>(
      0,
      (previousValue, text) => previousValue + text.keywords.length,
    );

    notifyListeners();
  }

  // Helpers to load history
  // Note: The texts returned from the repository are for the requested local time period,
  // but the text timestamps are still in UTC for consistency.
  // The text timestamps themselves are not used in the stats, focusing on counts.
  void _loadDayHistory() {
    final today = DateTime.now();
    final todayHistory = _repo.getLocalDayTexts(today);

    // Clear and reload the day's history
    _dayTextHistory
      ..clear()
      ..addAll(todayHistory.reversed);

    _totalDayCount = _dayTextHistory.fold<int>(
      0,
      (previousValue, text) => previousValue + text.keywords.length,
    );
    _currentDay = today;
  }

  void _loadWeekHistory() {
    final today = DateTime.now();
    final weekHistory = _repo.getLocalWeekTexts(today);

    // Clear and reload the week's history
    _weekTextHistory
      ..clear()
      ..addAll(weekHistory.reversed);

    _totalWeekCount = _weekTextHistory.fold<int>(
      0,
      (previousValue, text) => previousValue + text.keywords.length,
    );
    _currentWeek = today;
  }

  void _loadMonthHistory() {
    final today = DateTime.now();
    final monthHistory = _repo.getLocalMonthTexts(today);

    // Clear and reload the month's history
    _monthTextHistory
      ..clear()
      ..addAll(monthHistory.reversed);

    _totalMonthCount = _monthTextHistory.fold<int>(
      0,
      (previousValue, text) => previousValue + text.keywords.length,
    );
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
    final yesterdayHistory = _repo.getLocalDayTexts(yesterday);

    _totalLastDayCount = yesterdayHistory.fold<int>(
      0,
      (previousValue, text) => previousValue + text.keywords.length,
    );
  }

  void _loadLastWeekHistoryCount() {
    final lastWeekDay = _currentWeek.subtract(const Duration(days: 7));
    final lastWeekHistory = _repo.getLocalWeekTexts(lastWeekDay);

    _totalLastWeekCount = lastWeekHistory.fold<int>(
      0,
      (previousValue, text) => previousValue + text.keywords.length,
    );
  }

  void _loadLastMonthHistoryCount() {
    // Calculate last month, if current month is January, last month is December of previous year
    final lastMonth = _currentMonth.month == DateTime.january
        ? DateTime(_currentMonth.year - 1, DateTime.december)
        : DateTime(_currentMonth.year, _currentMonth.month - 1);

    final lastMonthHistory = _repo.getLocalMonthTexts(lastMonth);

    _totalLastMonthCount = lastMonthHistory.fold<int>(
      0,
      (previousValue, text) => previousValue + text.keywords.length,
    );
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

  // Helpers for updating last7DaysTextsMap and last30DaysTextsMap
  void _loadRecentDaysTextsMaps() {
    // TODO: Settings Page should determine whether to pad empty days or not, which should also affect the UI styling of the charts
    // In case of not padding empty days, the chart will display last X days with data regardless of if they are consecutive or not (could be really old).
    // If using non-padded mode, the chart's X axis labels should also reflect the actual dates of the data points not just weekday names.
    final bool padEmptyDays = true;
    _last7DaysTextsMap = _repo.getRecentLocalDaysTextsMap(
      _currentDay,
      7,
      padEmptyDays,
    );
    _last30DaysTextsMap = _repo.getRecentLocalDaysTextsMap(
      _currentDay,
      30,
      padEmptyDays,
    );
  }

  void _loadRecentDaysKeywordsCountsMaps() {
    _last7DaysCountsMap = _last7DaysTextsMap.map(
      (day, texts) => MapEntry(
        day,
        texts.fold<int>(
          0,
          (previousValue, text) => previousValue + text.keywords.length,
        ),
      ),
    );

    _last30DaysCountsMap = _last30DaysTextsMap.map(
      (day, texts) => MapEntry(
        day,
        texts.fold<int>(
          0,
          (previousValue, text) => previousValue + text.keywords.length,
        ),
      ),
    );
  }

  // Helpers for things to do when day/week/month changes
  void _onDayChanged() {
    _loadDayHistory();
    _loadLastDayHistoryCount();
    _dayPercentChange();
    _loadRecentDaysTextsMaps();
    _loadRecentDaysKeywordsCountsMaps();
  }

  void _onWeekChanged() {
    _loadWeekHistory();
    _loadLastWeekHistoryCount();
    _weekPercentChange();
    _loadRecentDaysTextsMaps();
    _loadRecentDaysKeywordsCountsMaps();
  }

  void _onMonthChanged() {
    _loadMonthHistory();
    _loadLastMonthHistoryCount();
    _monthPercentChange();
    _loadRecentDaysTextsMaps();
    _loadRecentDaysKeywordsCountsMaps();
  }

  // Helper to initialize all states
  void _init() {
    // Load histories to update initial states
    _loadHistory();
    _loadLastHistoryCounts();

    // Calculate initial percentage changes
    _percentChanges();

    // Load last 7 and 30 days texts maps and count maps for charts
    _loadRecentDaysTextsMaps();
    _loadRecentDaysKeywordsCountsMaps();
  }

  // Chart-related functions
  // Set the chart time frame
  void setChartTimeFrame(ChartTimeFrame timeframe) {
    if (timeframe == _selectedChartTimeFrame) return;
    _selectedChartTimeFrame = timeframe;
    notifyListeners();
  }

  // Returns the selected days counts map based on the current chart time frame index
  Map<DateTime, int> get selectedDaysCountsMap {
    switch (_selectedChartTimeFrame) {
      case ChartTimeFrame.week:
        return _last7DaysCountsMap;
      case ChartTimeFrame.month:
        return _last30DaysCountsMap;
    }
  }

  // Returns the maximum Y value for the chart
  double get chartMaxY {
    if (selectedDaysCountsMap.isEmpty) return 5.0;
    return selectedDaysCountsMap.values
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
  }
}
