import 'package:catch_this_ai/core/domain/tracked_keyword.dart';
import 'package:catch_this_ai/core/storage/db/db_manager.dart';
import 'package:hive_flutter/adapters.dart';

/// Local storage service for tracking keywords using Hive box
class TrackingLocalStorage {
  late final DBManager _dbManager;

  late Box<TrackedKeyword> _trackingBox;

  TrackingLocalStorage(this._dbManager);

  // Open the box for tracked keywords
  Future<void> init() async {
    const String boxName = 'tracked_keywords_box';

    _trackingBox = await _dbManager.openBox<TrackedKeyword>(boxName);
  }

  // Add a tracked keyword to the local storage
  Future<void> addTrackedKeyword(TrackedKeyword trackedKeyword) async {
    await _trackingBox.add(trackedKeyword);
  }

  // Retrieve all tracked keywords from local storage
  List<TrackedKeyword> getAllTrackedKeywords() {
    return _trackingBox.values.toList();
  }

  // Retrieve all tracked keywords in a day
  List<TrackedKeyword> getTrackedKeywordsDay(DateTime day) {
    return _trackingBox.values
        .where(
          (keyword) =>
              keyword.timestamp.year == day.year &&
              keyword.timestamp.month == day.month &&
              keyword.timestamp.day == day.day,
        )
        .toList();
  }

  // Get tracked keywords for the week before the given day from local storage
  // Week is considered to start from Monday to Sunday
  List<TrackedKeyword> getTrackedKeywordsWeek(DateTime day) {
    final startOfWeek = day.subtract(
      Duration(days: day.weekday - DateTime.monday),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 7)); // Next Monday
    return _trackingBox.values
        .where(
          (keyword) =>
              // Not before start of week to make it inclusive
              !keyword.timestamp.isBefore(startOfWeek) &&
              // Before the next monday to make it inclusive of the last day (sunday)
              keyword.timestamp.isBefore(endOfWeek),
        )
        .toList();
  }

  // Retrieve all tracked keywords in a month
  List<TrackedKeyword> getTrackedKeywordsMonth(DateTime month) {
    return _trackingBox.values
        .where(
          (keyword) =>
              keyword.timestamp.year == month.year &&
              keyword.timestamp.month == month.month,
        )
        .toList();
  }

  // Clear all tracked keywords from local storage
  Future<void> clearTrackedKeywords() async {
    await _trackingBox.clear();
  }

  // Close the Hive box
  Future<void> dispose() async {
    await _trackingBox.close();
  }
}
