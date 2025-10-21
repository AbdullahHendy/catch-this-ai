import 'dart:async';
import 'dart:typed_data';
import 'package:catch_this_ai/core/utils/audio_utils.dart';
import 'package:record/record.dart';

/// Service to handle audio streaming from the microphone and emit Float32List audio data
class AudioStreamService {
  // Instance of the audio recorder
  late final AudioRecorder _audioRecorder = AudioRecorder();

  // Stream controller to send Float32List audio data to listeners
  // Broadcast stream to allow possible multiple listeners to subscribe
  final _controller = StreamController<Float32List>.broadcast();

  // Subscription to monitor recording state changes from modules that use the recorder
  StreamSubscription<RecordState>? _recordSubscription;

  // Flag to indicate if recording is in progress
  bool _isRecording = false;

  // Getter for the audio data (Float32List) stream to allow listeners to subscribe and do something like:
  // audioStreamService.stream.listen((audioData) { ... });
  // similar to what's done BELOW to get raw byte data from the recorder stream: recordStream.listen((data) { ... });
  Stream<Float32List> get stream => _controller.stream;

  // Start audio recording and streaming
  Future<void> start() async {
    if (_isRecording) return;

    // NOTE: This service is expected to be started in a foreground service (different isolate) that has microphone permission already granted.
    // TODO: Maybe leave the code below uncommented with a `if(inMainIsolate)` check to
    // make it generic enough to be used in both foreground service and main isolate.

    // // Check and request microphone permission
    // final hasPermission = await _audioRecorder.hasPermission();
    // if (!hasPermission) {
    //   throw Exception('Microphone permission denied');
    // }

    // Recording configuration
    const sampleRate = 16000;
    const numChannels = 1;
    const encoder = AudioEncoder.pcm16bits;
    final isEncoderSupported = await _audioRecorder.isEncoderSupported(encoder);
    if (!isEncoderSupported) {
      throw Exception('Audio encoder not supported: $encoder');
    }

    const recordConfig = RecordConfig(
      encoder: encoder,
      sampleRate: sampleRate,
      numChannels: numChannels,
    );

    // Start recording and listen to the audio stream
    final recordStream = await _audioRecorder.startStream(recordConfig);

    recordStream.listen((rawData) {
      final float32ListData = convertBytesToFloat32List(
        Uint8List.fromList(rawData),
      );
      _controller.add(float32ListData);
    }, onError: (e, st) => _controller.addError(e, st));

    // Update recording state
    _isRecording = true;

    // Monitor recording state changes
    _recordSubscription = _audioRecorder.onStateChanged().listen((state) {
      if (state == RecordState.stop) {
        _isRecording = false;
      }
    });
  }

  // Stop audio recording and streaming
  Future<void> stop() async {
    if (!_isRecording) return;
    await _audioRecorder.stop();
    _isRecording = false;
  }

  // Dispose the service and release resources
  Future<void> dispose() async {
    await stop();
    _recordSubscription?.cancel();
    _controller.close();
    _audioRecorder.dispose();
  }
}
