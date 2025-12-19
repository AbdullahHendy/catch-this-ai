import 'dart:async';
import 'dart:typed_data';
import 'package:catch_this_ai/core/domain/tracked_text.dart';
import 'package:catch_this_ai/core/utils/sherpa_model_utils.dart';

// Abstract service to define speech-to-text functionality
// This can be implemented by different services like ASR or KWS
abstract class SpeechToTextService {
  // Getter for the tracked text stream to allow listeners to subscribe and do something like:
  // speechToTextService.stream.listen((trackedText) { ... });
  Stream<TrackedText> get stream;

  // Initialize the service with the given the Enum SherpaModel
  Future<void> init(SherpaModel model);

  // Process audio data chunks to detect texts
  void detectTexts(Float32List audioData);

  // Dispose the service and release resources
  Future<void> dispose();
}
