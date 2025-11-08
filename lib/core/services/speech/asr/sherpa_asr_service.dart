import 'dart:async';
import 'dart:typed_data';
import 'package:catch_this_ai/core/domain/tracked_text.dart';
import 'package:catch_this_ai/core/services/speech/speech_to_text_service.dart';
import 'package:catch_this_ai/core/utils/sherpa_model_utils.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

/// Service to manage Sherpa ASR model loading, transcription, and keyword retrieval
/// Implements the SpeechToTextService interface
class SherpaAsrService implements SpeechToTextService {
  // Sherpa ONNX ASR model and stream instances
  sherpa_onnx.OnlineRecognizer? _recognizer;
  sherpa_onnx.OnlineStream? _stream;

  // Flag to indicate if the service has been initialized
  bool _isInitialized = false;

  // Stream controller to send transcribed text to listeners
  // Broadcast stream to allow possible multiple listeners to subscribe
  final _controller = StreamController<TrackedText>.broadcast();

  // Getter for the transcriptions stream to allow listeners to subscribe and do something like:
  // sherpaAsrService.stream.listen((transcription) { ... });
  @override
  Stream<TrackedText> get stream => _controller.stream;

  // Keywords list
  List<String> _keywords = [];

  // Map to store regex patterns for keywords for quick access
  final Map<String, RegExp> _keywordPatterns = {};

  // Available ASR model names
  static const List<String> availableModelNames = [
    'sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20',
  ];

  // Initialize the Sherpa ASR model and load hotwords
  @override
  Future<void> init(String modelName) async {
    if (_isInitialized) return;
    if (!availableModelNames.contains(modelName)) {
      throw Exception(
        'Model $modelName is not in the list of available ASR models.',
      );
    }

    // Sherpa ONNX stream and model initialization
    sherpa_onnx.initBindings();
    final modelConfig = await getOnlineModelConfig(modelName: modelName);
    final hotwordsFilePath = await getKeywordsFilePath(modelName);
    // List of the content of the hotwords file
    _keywords = await getRawKeywords(modelName);

    // Precompile regex patterns for all keywords
    for (final keyword in _keywords) {
      final pattern = RegExp(
        r'\b' + RegExp.escape(keyword) + r'\b',
        caseSensitive: false,
      );
      _keywordPatterns[keyword] = pattern;
    }

    // Hotwords score boost value fallback if not specified in hotwords file
    const hotwordsScoreBoost = 1.5;
    final asrConfig = sherpa_onnx.OnlineRecognizerConfig(
      model: modelConfig,
      decodingMethod: 'modified_beam_search',
      hotwordsFile: hotwordsFilePath,
      hotwordsScore: hotwordsScoreBoost,
    );

    _recognizer = sherpa_onnx.OnlineRecognizer(asrConfig);
    _stream = _recognizer?.createStream();

    _isInitialized = true;
  }

  @override
  void detectTexts(Float32List audioData) {
    if (!_isInitialized || _recognizer == null || _stream == null) {
      throw Exception('Sherpa ASR Service is not initialized');
    }

    const sampleRate = 16000;
    _stream!.acceptWaveform(samples: audioData, sampleRate: sampleRate);

    while (_recognizer!.isReady(_stream!)) {
      _recognizer!.decode(_stream!);
    }
    final result = _recognizer!.getResult(_stream!);
    final transcription = result.text;

    if (_recognizer!.isEndpoint(_stream!)) {
      // If endpoint is detected, emit the transcription only if it contains any of the keywords and reset the stream
      if (transcription.isNotEmpty) {
        // Use the precompiled regex patterns to find keywords in the transcription
        final detectedKeywords = _keywordPatterns.entries.expand((entry) {
          final keyword = entry.key;
          final pattern = entry.value;

          final allMatches = pattern.allMatches(transcription);
          return allMatches.map((match) => keyword);
        }).toList();

        if (detectedKeywords.isNotEmpty) {
          // Create TrackedText with current timestamp in UTC
          final trackedText = TrackedText(
            transcription,
            detectedKeywords,
            DateTime.now().toUtc(),
          );
          _controller.add(trackedText);
        }
      }

      _recognizer!.reset(_stream!);
    }
  }

  // Dispose resources
  @override
  Future<void> dispose() async {
    _controller.close();
    _stream!.free();
    _recognizer!.free();
    _isInitialized = false;
  }
}
