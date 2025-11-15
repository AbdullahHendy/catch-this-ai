import 'package:catch_this_ai/core/storage/db/db_manager.dart';
import 'package:hive_flutter/adapters.dart';

/// Local storage service for app settings using Hive box
class SettingsLocalStorage {
  late final DBManager _dbManager;

  late Box _settingsBox;

  // Keys for settings
  static const String keySpeechServiceType = 'speech_service_type';
  static const String keywordsOnlyMode = 'keywords_only_mode';
  static const String padEmptyDaysInCharts = 'pad_empty_days_in_charts';

  SettingsLocalStorage(this._dbManager);

  // Open the box for app settings
  Future<void> init() async {
    const String boxName = 'app_settings_box';

    _settingsBox = await _dbManager.openBox(boxName);
  }

  // Setter and getter for speech service type
  Future<void> setSpeechServiceType(String serviceType) async {
    await _settingsBox.put(keySpeechServiceType, serviceType);
  }

  String getSpeechServiceType() {
    return _settingsBox.get(keySpeechServiceType, defaultValue: 'asr');
  }

  // Setter and getter for keywords only mode
  Future<void> setKeywordsOnlyMode(bool isEnabled) async {
    await _settingsBox.put(keywordsOnlyMode, isEnabled);
  }

  bool getKeywordsOnlyMode() {
    return _settingsBox.get(keywordsOnlyMode, defaultValue: false);
  }

  // Setter and getter for pad empty days in charts
  Future<void> setPadEmptyDaysInCharts(bool pad) async {
    await _settingsBox.put(padEmptyDaysInCharts, pad);
  }

  bool getPadEmptyDaysInCharts() {
    return _settingsBox.get(padEmptyDaysInCharts, defaultValue: true);
  }

  // Clear all settings
  Future<void> clearSettings() async {
    await _settingsBox.clear();
  }

  // Close the Hive box
  Future<void> dispose() async {
    await _settingsBox.close();
  }
}
