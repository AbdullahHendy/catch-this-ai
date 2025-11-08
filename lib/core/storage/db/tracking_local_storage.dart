import 'package:catch_this_ai/core/domain/tracked_text.dart';
import 'package:catch_this_ai/core/storage/db/db_manager.dart';
import 'package:hive_flutter/adapters.dart';

/// Local storage service for tracking texts using Hive box
class TrackingLocalStorage {
  late final DBManager _dbManager;

  late Box<TrackedText> _trackingBox;

  TrackingLocalStorage(this._dbManager);

  // Open the box for tracked texts
  Future<void> init() async {
    const String boxName = 'tracked_texts_box';

    _trackingBox = await _dbManager.openBox<TrackedText>(boxName);
  }

  // Add a tracked text to the local storage
  Future<void> addTrackedText(TrackedText trackedText) async {
    await _trackingBox.add(trackedText);
  }

  // Retrieve all tracked texts from local storage
  List<TrackedText> getAllTrackedTexts() {
    return _trackingBox.values.toList();
  }

  // Clear all tracked texts from local storage
  Future<void> clearTrackedTexts() async {
    await _trackingBox.clear();
  }

  // Close the Hive box
  Future<void> dispose() async {
    await _trackingBox.close();
  }
}
