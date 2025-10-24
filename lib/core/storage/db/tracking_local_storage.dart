import 'package:catch_this_ai/core/domain/tracked_keyword.dart';
import 'package:hive_flutter/adapters.dart';

/// Singleton local storage service for tracking keywords using Hive
/// It's made singleton to ensure only one instance manages the Hive box
class TrackingLocalStorage {
  TrackingLocalStorage._();
  static final TrackingLocalStorage instance = TrackingLocalStorage._();

  late Box<TrackedKeyword> _box;

  // Initialize Hive and open the box for tracked keywords
  Future<void> init() async {
    const String boxName = 'tracked_keywords_box';

    // Check if box is already opened
    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box<TrackedKeyword>(boxName);
      return;
    }

    await Hive.initFlutter();

    // Register the adapter for TrackedKeyword if not already registered
    const int adapterId = 0;
    if (!Hive.isAdapterRegistered(adapterId)) {
      Hive.registerAdapter(TrackedKeywordAdapter());
    }

    _box = await Hive.openBox<TrackedKeyword>(boxName);
  }

  // Add a tracked keyword to the local storage
  Future<void> addTrackedKeyword(TrackedKeyword trackedKeyword) async {
    await _box.add(trackedKeyword);
  }

  // Retrieve all tracked keywords from local storage
  List<TrackedKeyword> getAllTrackedKeywords() {
    return _box.values.toList();
  }

  // Retrieve all tracked keywords in a day
  List<TrackedKeyword> getTrackedKeywordsDay(DateTime day) {
    return _box.values
        .where(
          (keyword) =>
              keyword.timestamp.year == day.year &&
              keyword.timestamp.month == day.month &&
              keyword.timestamp.day == day.day,
        )
        .toList();
  }

  // Get tracked keywords for the week before the given day from local storage
  List<TrackedKeyword> getTrackedKeywordsWeek(DateTime day) {
    final weekKeywords = <TrackedKeyword>[];
    for (int i = 0; i < 7; i++) {
      final currentDay = day.subtract(Duration(days: i));
      weekKeywords.addAll(getTrackedKeywordsDay(currentDay));
    }
    return weekKeywords;
  }

  // Retrieve all tracked keywords in a month
  List<TrackedKeyword> getTrackedKeywordsMonth(DateTime month) {
    return _box.values
        .where(
          (keyword) =>
              keyword.timestamp.year == month.year &&
              keyword.timestamp.month == month.month,
        )
        .toList();
  }

  // Clear all tracked keywords from local storage
  Future<void> clearTrackedKeywords() async {
    await _box.clear();
  }

  // Close the Hive box
  Future<void> dispose() async {
    await _box.close();
  }
}
