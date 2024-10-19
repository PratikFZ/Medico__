import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();
  factory NotificationService() {
    return _notificationService;
  }
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings("/home/pratik/My Projects/Medico_proj/src/frontend/assets/icon.jpg");

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(int id, String title, String body) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          'Alarm Notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        ),
      ),
    );
  }
}

void handleNotificaion(BuildContext context) {
  // final notificationService = NotificationService();

  Alarm.ringStream.stream.listen((_) async {
    // Show notification
    // await notificationService.showNotification(
    //   1,
    //   'Medication Reminder',
    //   'It\'s time to take your medicine!',
    // );

    // Optionally, you can still show a dialog or navigate to a specific page
    // if you want additional UI interaction
    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Medication Reminder'),
        content: Text('It\'s time to take your medicine!'),
        actions: [
          TextButton(
            onPressed: () {
              Alarm.stop(1);
              Navigator.pop(context);
            },
            child: Text('Dismiss'),
          ),
        ],
      ),
    );
  });
}