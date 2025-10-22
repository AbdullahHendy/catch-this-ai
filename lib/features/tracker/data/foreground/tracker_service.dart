import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:catch_this_ai/features/tracker/domain/tracked_keyword.dart';
import 'package:catch_this_ai/features/tracker/data/foreground/tracker_task_handler.dart';
import 'package:record/record.dart';

// Callback type definition for handling tracked keywords from the foreground service
typedef TrackedKeywordCallback = void Function(TrackedKeyword);

/// Singleton tracker service to manage foreground tracking tasks
/// It's made singleton since only one tracking service should be active at a time
class TrackerService {
  TrackerService._();

  static final TrackerService instance = TrackerService._();

  // ------------- Service API -------------
  Future<void> requestPermissions() async {
    // Request notification permission for foreground service
    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    // Check and request Microphone permission since this service type is microphone
    // Declared in AndroidManifest.xml for android:foregroundServiceType="microphone"
    final microphonePermission = await AudioRecorder().hasPermission();
    if (!microphonePermission) {
      throw Exception('Microphone permission denied');
    }

    if (Platform.isAndroid) {
      // Android 12+, there are restrictions on starting a foreground service.
      // To restart the service on device reboot or unexpected problem, ignore battery optimizations should be allowed.
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        // The following function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      // TODO: Check if the following commented code is necessary

      // // Use this utility only if you provide services that require long-term survival,
      // // such as exact alarm service, healthcare service, or Bluetooth communication.
      // //
      // // This utility requires the "android.permission.SCHEDULE_EXACT_ALARM" permission.
      // // Using this permission may make app distribution difficult due to Google policy.
      // if (!await FlutterForegroundTask.canScheduleExactAlarms) {
      //   // When you call this function, will be gone to the settings page.
      //   // So you need to explain to the user why set it.
      //   await FlutterForegroundTask.openAlarmsAndRemindersSettings();
      // }
    }
  }

  // Initialize the foreground tracking service
  Future<void> init() async {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'tracker_service',
        channelName: 'Keyword Tracker Service',
        channelDescription:
            'This notification appears when the keyword tracker is running in the foreground.',
        channelImportance: NotificationChannelImportance.MAX,
        priority: NotificationPriority.MAX,
        playSound: true,
        enableVibration: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: true,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  // Start the foreground tracking service. Should init() and requestPermissions() first.
  Future<void> start() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
    } else {
      // Notification buttons, texts are updated later in the TrackerTaskHandler
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'Catching This AI',
        notificationText: '',
        notificationIcon: null,
        notificationButtons: const [],
        notificationInitialRoute: '/',
        callback:
            trackerTaskHandler, // top-level callback that sets TaskHandler from tracker_task_handler.dart
      );
    }
  }

  // Stop the foreground tracking service
  Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  // Useful getter to check if the foreground tracking service is running
  Future<bool> get isRunning => FlutterForegroundTask.isRunningService;

  // ------------- Service Callbacks -------------

  // List of registered callbacks to notify when a tracked keyword is received
  // This is for future profing in case multiple parts of the app want to listen to tracked keywords
  // Right now only one listener is used in the ViewModel
  final List<TrackedKeywordCallback> _callbacks = [];

  // Add a callback to be notified when a tracked keyword is received
  void registerTrackedKeywordCallback(TrackedKeywordCallback callback) {
    if (!_callbacks.contains(callback)) _callbacks.add(callback);
  }

  // Remove a previously registered callback
  void unregisterTrackedKeywordCallback(TrackedKeywordCallback callback) {
    _callbacks.remove(callback);
  }

  // Internal method to handle data received from the foreground task
  void _onReceiveTaskData(Object data) {
    // Check if the data is a tracked keyword map
    bool isTrackedKeywordData =
        data is Map<String, dynamic> &&
        data.containsKey('keyword') &&
        data.containsKey('timestamp');

    if (isTrackedKeywordData) {
      final trackedKeyword = TrackedKeywordSerialization.fromMap(data);
      // Execute all registered callbacks with the received tracked keyword
      for (final callback in _callbacks) {
        callback(trackedKeyword);
      }
    }

    // Check if data is exitApp command (sent from TrackerTaskHandler when user presses exit button on notification)
    bool isExitCommand = data is String && data == TaskCommands.exitApp;
    if (isExitCommand) {
      stop().then((_) {
        SystemNavigator.pop();
      });
    }

    // Check if the data is debug information (used to send debug strings from the task since it's in a different isolate)
    bool isDebugData = data is String && data.startsWith('DEBUG:');
    if (isDebugData) {
      debugPrint('Foreground Task Debug: $data');
    }
  }

  Future<void> dispose() async {
    await stop();
    // Remove a callback to receive data sent from the TaskHandler.
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    _callbacks.clear();
  }
}
