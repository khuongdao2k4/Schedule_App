import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    // Create notification channel for high importance
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_deadline_channel',
      'Thông báo Nhiệm vụ',
      description: 'Thông báo về thời gian bắt đầu và kết thúc nhiệm vụ',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> scheduleTaskNotifications(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final bool notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    if (!notificationsEnabled) return;

    if (task.id == null) return;
    int baseId = task.id.hashCode;

    // Schedule Start Notification
    if (task.startTime != null && task.startTime!.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: baseId,
        title: 'Nhiệm vụ Bắt đầu: ${task.title}',
        body: 'Đã đến lúc thực hiện công việc của bạn!',
        scheduledDate: task.startTime!,
      );
    }

    // Schedule End Notification (Deadline)
    if (task.endTime != null && task.endTime!.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: baseId + 1,
        title: 'Hạn chót: ${task.title}',
        body: 'Nhiệm vụ này đã đến thời gian kết thúc!',
        scheduledDate: task.endTime!,
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_deadline_channel',
          'Thông báo Nhiệm vụ',
          channelDescription: 'Thông báo về thời gian bắt đầu và kết thúc nhiệm vụ',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction('dismiss', 'Đóng', cancelNotification: true),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelTaskNotifications(String taskId) async {
    int baseId = taskId.hashCode;
    await _notificationsPlugin.cancel(baseId);
    await _notificationsPlugin.cancel(baseId + 1);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
