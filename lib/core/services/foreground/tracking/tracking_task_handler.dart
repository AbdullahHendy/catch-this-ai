import 'dart:async';
import 'dart:typed_data';
import 'package:catch_this_ai/core/services/audio/audio_stream_service.dart';
import 'package:catch_this_ai/core/services/kws/sherpa_kws_service.dart';
import 'package:catch_this_ai/core/domain/tracked_keyword.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:record/record.dart';

// Top-level callback function to handle tracked keywords in the foreground task
@pragma('vm:entry-point')
void trackerTaskHandler() {
  FlutterForegroundTask.setTaskHandler(TrackerTaskHandler());
}

/// Foreground task handler to manage tracking keywords
class TrackerTaskHandler extends TaskHandler {
  // instances of audio stream service and kws service
  late final AudioStreamService _audioService;
  late final SherpaKwsService _kwsService;

  // Subscription to audio stream and kws service to get handle to stop them later
  StreamSubscription<Float32List>? _audioSub;
  StreamSubscription<String>? _kwsSub;

  // Subscription to recording state changes to update notification accordingly
  StreamSubscription<RecordState>? _recordingStateSub;

  // onStart is called when the foreground task starts
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _audioService = AudioStreamService();
    _kwsService = SherpaKwsService();

    // Initialize kws
    const modelName = 'sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01';
    await _kwsService.init(modelName);

    // Start audio streaming
    await _audioService.start();

    // Listen to audio stream and pass audio data to KWS service for keyword detection
    _audioSub = _audioService.audioStream.listen((audioData) {
      _kwsService.detectKeywords(audioData);
    });

    // Listen to detected keywords from KWS service and send them through the controller
    _kwsSub = _kwsService.stream.listen((keyword) {
      final trackedKeyword = TrackedKeyword(keyword, DateTime.now());
      // Send the tracked keyword to the main isolate
      FlutterForegroundTask.sendDataToMain(trackedKeyword.toMap());
    });

    // Listen to recording state changes to update notification accordingly
    _recordingStateSub = _audioService.stateStream.listen((state) async {
      await _updateNotification();
    });
  }

  // onRepeatEvent is called on each interval defined in ForegroundTaskOptions
  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // No periodic action needed for now, maybe add heartbeat or status update later
    // If so, remember to change `eventAction: ForegroundTaskEventAction.nothing()` in ForegroundTaskOptions in tracker_service.dart
  }

  // onDestroy is called when the foreground task is stopped (FlutterForegroundTask.stopService())
  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _audioSub?.cancel();
    await _kwsSub?.cancel();
    await _recordingStateSub?.cancel();
    await _kwsService.dispose();
    await _audioService.dispose();
  }

  // onReceiveData is called when data is sent using `FlutterForegroundTask.sendDataToTask`.
  @override
  void onReceiveData(Object data) {
    // Not used here, as we only send data to the main isolate
    debugPrint('onReceiveData: $data');
  }

  // onNotificationButtonPressed is called when the notification button is pressed.
  @override
  Future<void> onNotificationButtonPressed(String id) async {
    switch (id) {
      case 'btn_start':
        if (_audioService.recordingState != RecordState.record) {
          await _audioService.start();
        }

      case 'btn_resume':
        if (_audioService.recordingState == RecordState.pause) {
          await _audioService.resume();
        }

      case 'btn_stop':
        if (_audioService.recordingState != RecordState.stop) {
          await _audioService.stop();
        }

      case 'btn_exit':
        // Callback handles app exit in the main isolate, see _onReceiveTaskData in tracker_service.dart
        FlutterForegroundTask.sendDataToMain(TaskCommands.exitApp);

      default:
        break;
    }
  }

  // onNotificationPressed is called when the notification itself is pressed.
  @override
  void onNotificationPressed() {
    debugPrint('onNotificationPressed');
  }

  // onNotificationDismissed is called when the notification itself is dismissed.
  @override
  void onNotificationDismissed() {
    // If notification is dismissed, bring it back since its needed for controls like stop/start/exit
    // Effectively makes the notification sticky/undismissable
    _updateNotification();
  }

  // Helper method to update the service notification buttons and text based on the recording state
  Future<void> _updateNotification() async {
    // Read the recording state from the audio service
    final state = _audioService.recordingState;

    String notificationText;
    List<NotificationButton> buttons;

    // Update notification text and buttons based on recording states (record, pause, stop)
    switch (state) {
      case RecordState.record:
        notificationText = 'Catching...';
        buttons = const [
          NotificationButton(id: 'btn_stop', text: 'Stop'),
          NotificationButton(id: 'btn_exit', text: 'Exit'),
        ];
      case RecordState.pause:
        notificationText = 'Paused Catching...';
        buttons = const [
          NotificationButton(id: 'btn_resume', text: 'Resume'),
          NotificationButton(id: 'btn_exit', text: 'Exit'),
        ];
      case RecordState.stop:
        notificationText = 'Not Catching...';
        buttons = const [
          NotificationButton(id: 'btn_start', text: 'Start'),
          NotificationButton(id: 'btn_exit', text: 'Exit'),
        ];
    }

    FlutterForegroundTask.updateService(
      notificationText: notificationText,
      notificationButtons: buttons,
    );
  }
}

/// Commands that can be sent to the foreground task
class TaskCommands {
  static const String exitApp = 'EXIT_APP';
  static const String debugHeartbeat = 'DEBUG: HEARTBEAT'; // unused for now
}
