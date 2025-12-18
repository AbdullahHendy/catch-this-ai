import 'dart:async';
import 'dart:typed_data';
import 'package:catch_this_ai/core/domain/tracked_text.dart';
import 'package:catch_this_ai/core/services/speech/speech_to_text_service.dart';
import 'package:catch_this_ai/core/utils/sherpa_model_utils.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

/// Service to manage Sherpa KWS model loading and keyword retrieval
/// Implements the SpeechToTextService interface
class SherpaKwsService implements SpeechToTextService {
  // Sherpa ONNX keyword spotter and stream instances
  sherpa_onnx.KeywordSpotter? _spotter;
  sherpa_onnx.OnlineStream? _stream;

  // Flag to indicate if the service has been initialized
  bool _isInitialized = false;

  // Stream controller to send TrackedText objects to listeners
  // Broadcast stream to allow possible multiple listeners to subscribe
  final _controller = StreamController<TrackedText>.broadcast();

  // Getter for the detected texts stream to allow listeners to subscribe and do something like:
  // sherpaKwsService.stream.listen((detectedText) { ... });
  @override
  Stream<TrackedText> get stream => _controller.stream;

  // Initialize the Sherpa KWS model and load keywords
  @override
  Future<void> init(SherpaModel model) async {
    if (_isInitialized) return;

    // Sherpa ONNX stream and model initialization
    sherpa_onnx.initBindings();
    final modelConfig = await getOnlineModelConfig(model: model);
    final keywordsFilePath = await getKeywordsFilePath(model);
    // Seems to be a fallback threshold value if not specified in keywords file
    const keywordsThreshold = 0.1;
    final kwsConfig = sherpa_onnx.KeywordSpotterConfig(
      model: modelConfig,
      keywordsFile: keywordsFilePath,
      keywordsThreshold: keywordsThreshold,
    );

    _spotter = sherpa_onnx.KeywordSpotter(kwsConfig);
    _stream = _spotter?.createStream();

    _isInitialized = true;
  }

  @override
  void detectTexts(Float32List audioData) {
    if (!_isInitialized || _spotter == null || _stream == null) {
      throw Exception('SherpaKwsService is not initialized');
    }

    const sampleRate = 16000;
    _stream!.acceptWaveform(samples: audioData, sampleRate: sampleRate);

    while (_spotter!.isReady(_stream!)) {
      _spotter!.decode(_stream!);
    }
    final result = _spotter!.getResult(_stream!);

    if (result.keyword.isNotEmpty) {
      // Create TrackedText with current timestamp in UTC, keywords list is just the detected keyword
      final trackedText = TrackedText(result.keyword, [
        result.keyword,
      ], DateTime.now().toUtc());
      _controller.add(trackedText);

      // Reset the stream after a keyword is detected
      // TODO: Think about if this is the best way to reset the stream
      _spotter!.reset(_stream!);
    }
  }

  // Dispose resources
  @override
  Future<void> dispose() async {
    _controller.close();
    _stream!.free();
    _spotter!.free();
    _isInitialized = false;
  }
}
