import 'dart:async';
import 'dart:typed_data';
import 'package:catch_this_ai/core/audio/audio_stream_service.dart';
import 'package:catch_this_ai/core/kws/sherpa_kws_service.dart';
import 'package:catch_this_ai/features/tracker/domain/tracked_keyword.dart';

/// Repository to orchestrate audio streaming and keyword spotting
class TrackerRepository {
  // audio stream and kws services
  final AudioStreamService _audioService;
  final SherpaKwsService _kwsService;

  // Subscription to audio stream service to get a handle to stop it later
  StreamSubscription<Float32List>? _audioSub;

  // Stream controller to send TrackedKeyword objects to listeners
  // Broadcast stream to allow possible multiple listeners to subscribe
  final _controller = StreamController<TrackedKeyword>.broadcast();

  // Getter for the tracked keywords stream to allow listeners to subscribe and do something like:
  // trackerRepository.stream.listen((trackedKeyword) { ... });
  Stream<TrackedKeyword> get stream => _controller.stream;

  TrackerRepository(this._audioService, this._kwsService);

  Future<void> start() async {
    const modelName = 'sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01';
    // Initialize KWS service and start audio streaming
    await _kwsService.init(modelName);
    await _audioService.start();

    // Listen to audio stream and pass audio data to KWS service for keyword detection
    _audioSub = _audioService.stream.listen((audioData) {
      _kwsService.detectKeywords(audioData);
    });

    // Listen to detected keywords from KWS service and send them through the controller
    _kwsService.stream.listen((keyword) {
      final tracked = TrackedKeyword(keyword, DateTime.now());
      _controller.add(tracked);
    });
  }

  Future<void> stop() async {
    await _audioSub?.cancel();
    await _audioService.stop();
  }

  Future<void> dispose() async {
    await stop();
    _controller.close();
    await _kwsService.dispose();
    await _audioService.dispose();
  }
}
