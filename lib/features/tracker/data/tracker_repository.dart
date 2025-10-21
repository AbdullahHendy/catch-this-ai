import 'dart:async';
import 'dart:typed_data';
import 'package:catch_this_ai/core/audio/audio_stream_service.dart';
import 'package:catch_this_ai/core/kws/sherpa_kws_service.dart';
import 'package:catch_this_ai/features/tracker/data/local/tracker_local_storage.dart';
import 'package:catch_this_ai/features/tracker/domain/tracked_keyword.dart';

/// Repository to orchestrate audio streaming and keyword spotting
class TrackerRepository {
  // audio stream and kws services
  final AudioStreamService _audioService;
  final SherpaKwsService _kwsService;

  // local storage for tracked keywords
  final TrackerLocalStorage _localStorage;

  // Subscription to audio stream and kws service to get handle to stop them later
  StreamSubscription<Float32List>? _audioSub;
  StreamSubscription<String>? _kwsSub;

  // Stream controller to send TrackedKeyword objects to listeners
  // Broadcast stream to allow possible multiple listeners to subscribe
  final _controller = StreamController<TrackedKeyword>.broadcast();

  // Getter for the tracked keywords stream to allow listeners to subscribe and do something like:
  // trackerRepository.stream.listen((trackedKeyword) { ... });
  Stream<TrackedKeyword> get stream => _controller.stream;

  // Flag to indicate if the repository was started
  bool _isStarted = false;

  TrackerRepository(this._audioService, this._kwsService, this._localStorage);

  // Initialize repository and its services, local storage
  Future<void> init() async {
    // Initialize local storage
    await _localStorage.init();

    // Initialize KWS service with the desired model
    const modelName = 'sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01';
    await _kwsService.init(modelName);
  }

  // Start audio streaming, keyword spotting, and local storage
  Future<void> start() async {
    if (_isStarted) return;

    // Start audio streaming
    await _audioService.start();

    // Listen to audio stream and pass audio data to KWS service for keyword detection
    _audioSub = _audioService.stream.listen((audioData) {
      _kwsService.detectKeywords(audioData);
    });

    // Listen to detected keywords from KWS service and send them through the controller and store locally
    _kwsSub = _kwsService.stream.listen((keyword) {
      final tracked = TrackedKeyword(keyword, DateTime.now());
      _controller.add(tracked);
      _localStorage.addTrackedKeyword(tracked);
    });

    _isStarted = true;
  }

  // Get tracked keywords for a specific day from local storage
  List<TrackedKeyword> getHistoryForDay(DateTime day) {
    return _localStorage.getTrackedKeywordsDay(day);
  }

  // Stop audio streaming and keyword spotting
  Future<void> stop() async {
    await _kwsSub?.cancel();
    await _audioSub?.cancel();
    await _audioService.stop();
    _isStarted = false;
  }

  // Dispose resources
  Future<void> dispose() async {
    await stop();
    _controller.close();
    await _kwsService.dispose();
    await _audioService.dispose();
  }
}
