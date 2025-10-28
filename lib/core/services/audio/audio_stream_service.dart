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
  final _audioController = StreamController<Float32List>.broadcast();

  // Stream controller to send the pause state of RecordState to listeners
  // Broadcast stream to allow possible multiple listeners to subscribe
  final _stateController = StreamController<RecordState>.broadcast();

  // Subscription to monitor recording state changes from modules that use the recorder
  StreamSubscription<RecordState>? _recordSubscription;

  // Recording state
  RecordState _recordingState = RecordState.stop;

  // Getter for the audio data (Float32List) stream to allow listeners to subscribe and do something like:
  // audioStreamService.audioStream.listen((audioData) { ... });
  // similar to what's done BELOW to get raw byte data from the recorder stream: recordStream.listen((data) { ... });
  Stream<Float32List> get audioStream => _audioController.stream;

  // Similar getter for the recording state stream
  Stream<RecordState> get stateStream => _stateController.stream;

  // Getter for recording state
  RecordState get recordingState => _recordingState;

  // Flag to ensure we only subscribe once to the recorder state changes
  bool _isSubscribedToStateChanges = false;

  // Start audio recording and streaming
  Future<void> start() async {
    if (_recordingState == RecordState.record) return;

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

    // The first thing to do is to subscribe to state changes if not already done
    // This will make sure all state changes are captured even if they happen before start() is awaited
    if (!_isSubscribedToStateChanges) {
      _recordSubscription = _audioRecorder.onStateChanged().listen((state) {
        // Change state first before notifying listeners
        _recordingState = state;
        _stateController.add(_recordingState);
      });
      _isSubscribedToStateChanges = true;
    }

    // Start recording and listen to the audio stream
    final recordStream = await _audioRecorder.startStream(recordConfig);

    recordStream.listen((rawData) {
      final float32ListData = convertBytesToFloat32List(
        Uint8List.fromList(rawData),
      );
      _audioController.add(float32ListData);
    }, onError: (e, st) => _audioController.addError(e, st));
  }

  // Resume audio recording if paused
  Future<void> resume() async {
    if (_recordingState != RecordState.pause) return;
    await _audioRecorder.resume();
  }

  // Stop audio recording and streaming
  Future<void> stop() async {
    if (_recordingState == RecordState.stop) return;
    await _audioRecorder.stop();
  }

  // Dispose the service and release resources
  Future<void> dispose() async {
    await stop();
    _recordSubscription?.cancel();
    _audioController.close();
    _stateController.close();
    _audioRecorder.dispose();
    _isSubscribedToStateChanges = false;
  }
}
