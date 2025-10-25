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

  // Clear all tracked keywords from local storage
  Future<void> clearTrackedKeywords() async {
    await _trackingBox.clear();
  }

  // Close the Hive box
  Future<void> dispose() async {
    await _trackingBox.close();
  }
}
