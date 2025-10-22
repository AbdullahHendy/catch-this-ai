import 'dart:async';
import 'package:catch_this_ai/core/audio/audio_stream_service.dart';
import 'package:catch_this_ai/core/kws/sherpa_kws_service.dart';
import 'package:catch_this_ai/features/tracker/data/tracker_repository.dart';
import 'package:catch_this_ai/features/tracker/domain/tracked_keyword.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// Top-level callback function to handle tracked keywords in the foreground task
@pragma('vm:entry-point')
void trackerTaskHandler() {
  FlutterForegroundTask.setTaskHandler(TrackerTaskHandler());
}

/// Foreground task handler to manage tracking keywords
class TrackerTaskHandler extends TaskHandler {
  late final TrackerRepository _repository;
  StreamSubscription<TrackedKeyword>? _sub;

  // onStart is called when the foreground task starts
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Initialize and start the tracker repository to handle audio streaming and keyword spotting
    _repository = TrackerRepository(AudioStreamService(), SherpaKwsService());
    await _repository.init();
    await _repository.start();

    // Update the notification to reflect the tracking state
    await _updateNotification();

    // Listen to tracked keywords from the repository and send them to the main isolate
    _sub = _repository.stream.listen((trackedKeyword) {
      // Send the tracked keyword to the main isolate
      FlutterForegroundTask.sendDataToMain(trackedKeyword.toMap());
    });
  }

  // onRepeatEvent is called on each interval defined in ForegroundTaskOptions
  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // No periodic action needed for now, maybe add heartbeat or status update later
    // If so, remember to change `eventAction: ForegroundTaskEventAction.nothing()` in ForegroundTaskOptions in tracker_service.dart
  }

  // onDestroy is called when the foreground task is stopped
  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _sub?.cancel();
    await _repository.dispose();
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
        if (!_repository.isStarted) {
          await _repository.start();
          await _updateNotification();
        }

      case 'btn_stop':
        if (_repository.isStarted) {
          await _repository.stop();
          await _updateNotification();
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

  // Helper method to update the service notification buttons and text based on the repository state
  Future<void> _updateNotification() async {
    FlutterForegroundTask.updateService(
      notificationText: _repository.isStarted
          ? 'Catching...'
          : 'Not Catching...',
      notificationButtons: _repository.isStarted
          ? const [
              NotificationButton(id: 'btn_stop', text: 'Stop'),
              NotificationButton(id: 'btn_exit', text: 'Exit'),
            ]
          : const [
              NotificationButton(id: 'btn_start', text: 'Start'),
              NotificationButton(id: 'btn_exit', text: 'Exit'),
            ],
    );
  }
}

/// Commands that can be sent to the foreground task
class TaskCommands {
  static const String exitApp = 'EXIT_APP';
  static const String debugHeartbeat = 'DEBUG: HEARTBEAT';
}
