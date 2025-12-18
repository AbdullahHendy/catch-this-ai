import 'package:catch_this_ai/core/data/tracking_repository.dart';
import 'package:catch_this_ai/core/utils/sherpa_model_utils.dart';
import 'package:flutter/foundation.dart';

/// ViewModel to manage settings states and actions
class SettingsViewModel extends ChangeNotifier {
  final TrackingRepository _repo;

  // State variables
  String _currentServiceType = SherpaModel.asr.type;
  bool _keywordsOnlyMode = false;
  bool _padEmptyDaysInCharts = true;
  List<String> _modelRawKeywords = [];

  // Getters for state variables
  bool get keywordsOnlyMode => _keywordsOnlyMode;
  String get currentServiceType => _currentServiceType;
  bool get padEmptyDaysInCharts => _padEmptyDaysInCharts;
  List<String> get modelRawKeywords => _modelRawKeywords;

  SettingsViewModel(this._repo);

  // Start the ViewModel by loading current settings
  Future<void> start() async {
    _currentServiceType = _repo.getServiceType();
    _keywordsOnlyMode = _repo.getKeywordsOnlyMode();
    _padEmptyDaysInCharts = _repo.getPadEmptyDaysInCharts();
    _modelRawKeywords = await _repo.getModelRawKeywords(
      SherpaModel.getSherpaModel(_currentServiceType),
    );

    notifyListeners();
  }

  Future<void> updateServiceType(String newType) async {
    if (newType == _currentServiceType) return;

    _currentServiceType = newType;

    await _repo.switchSpeechServiceType(newType);
    _modelRawKeywords = await _repo.getModelRawKeywords(
      SherpaModel.getSherpaModel(newType),
    );
    notifyListeners();
  }

  Future<void> updateKeywordsOnlyMode(bool isEnabled) async {
    if (isEnabled == _keywordsOnlyMode) return;

    _keywordsOnlyMode = isEnabled;

    await _repo.setKeywordsOnlyMode(isEnabled);
    notifyListeners();
  }

  Future<void> updatePadEmptyDaysInCharts(bool pad) async {
    if (pad == _padEmptyDaysInCharts) return;

    _padEmptyDaysInCharts = pad;

    await _repo.setPadEmptyDaysInCharts(pad);
    notifyListeners();
  }

  // Clear Data
  Future<void> clearTrackingData() async {
    await _repo.clearTrackingData();
    notifyListeners();
  }

  Future<void> clearSettings() async {
    await _repo.clearSettings();
    _currentServiceType = _repo.getServiceType();
    _keywordsOnlyMode = _repo.getKeywordsOnlyMode();
    _padEmptyDaysInCharts = _repo.getPadEmptyDaysInCharts();
    notifyListeners();
  }
}
