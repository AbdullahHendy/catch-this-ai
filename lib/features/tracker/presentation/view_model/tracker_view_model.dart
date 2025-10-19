import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:catch_this_ai/features/tracker/data/tracker_repository.dart';
import 'package:catch_this_ai/features/tracker/domain/tracked_keyword.dart';

/// ViewModel to manage tracking state and data
class TrackingViewModel extends ChangeNotifier {
  // repository instance to handle tracking logic (audio service + kws service + local storage)
  final TrackerRepository _repository;

  // Subscription to have a handle to stop listening to tracked keywords later
  StreamSubscription<TrackedKeyword>? _trackWordSub;

  // State variables
  TrackedKeyword _lastKeyword = TrackedKeyword('', DateTime(2000));
  int _totalCount = 0;
  bool _isRunning = false;

  // Getters for state variables for easy access
  TrackedKeyword get lastKeyword => _lastKeyword;
  int get totalCount => _totalCount;
  bool get isRunning => _isRunning;

  TrackingViewModel(this._repository);

  // Initialize view model
  Future<void> init() async {
    // Initialize the repository and its services
    await _repository.init();

    // Load today's history to set initial state
    final todayHistory = _repository.getHistoryForDay(DateTime.now());
    _lastKeyword = todayHistory.isNotEmpty
        ? todayHistory.last
        : TrackedKeyword('', DateTime(2000));
    _totalCount = todayHistory.length;
  }

  // Start tracking process
  Future<void> start() async {
    if (_isRunning) return;

    // Start the tracking process in the repository (audio service + kws service)
    await _repository.start();

    // Listen to tracked keywords (TrackedKeyword) from the repository stream
    _trackWordSub = _repository.stream.listen((trackedKeyword) {
      _lastKeyword = trackedKeyword;
      _totalCount++;
      // Notify listeners (UI) about state changes
      notifyListeners();
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
    notifyListeners();
  }

  @override
  void dispose() {
    _trackWordSub?.cancel();
    super.dispose();
  }
}
