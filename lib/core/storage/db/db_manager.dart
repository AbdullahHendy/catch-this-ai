import 'package:catch_this_ai/core/domain/tracked_keyword.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Responsible for initializing and providing access to Hive database boxes.
/// It's made singleton to ensure only one DBManager instance exists.
class DBManager {
  DBManager._();
  static final DBManager instance = DBManager._();

  bool _isInitialized = false;

  // Initialize Hive and register all necessary adapters
  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Initialize all adapters
    // Map of adapter IDs to their registerAdapter function calls
    // This is done to avoid dynamic registration when doing registerAdapter() without explicitly specifying the adapter type
    final Map<int, Function()> adaptersReg = {
      0: () => Hive.registerAdapter<TrackedKeyword>(TrackedKeywordAdapter()),
    };

    for (var entry in adaptersReg.entries) {
      if (!Hive.isAdapterRegistered(entry.key)) {
        entry.value();
      }
    }

    _isInitialized = true;
  }

  // Open a Hive box with the given name and type
  Future<Box<T>> openBox<T>(String boxName) async {
    if (!_isInitialized) {
      await init();
    }

    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<T>(boxName);
    }
    return Hive.box<T>(boxName);
  }

  // Close a specific Hive box by name
  Future<void> closeBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).close();
    }
  }

  // Close all opened Hive boxes (Close the database)
  Future<void> closeAllBoxes() async {
    await Hive.close();
    _isInitialized = false;
  }
}
