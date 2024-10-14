import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

class AlarmManager extends StatefulWidget {
  @override
  _AlarmManagerState createState() => _AlarmManagerState();
}

class _AlarmManagerState extends State<AlarmManager> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  AudioPlayer audioPlayer = AudioPlayer();
  List<int> activeAlarms = [];

  @override
  void initState() {
    super.initState();
    initializeNotifications();
  }

  void initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleAlarm(DateTime scheduledTime, String tune) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'alarm_channel',
      'Alarms',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(tune),
      playSound: true,
    );
    var iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      sound: tune,
      presentSound: true,
    );
    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await flutterLocalNotificationsPlugin.schedule(
      id,
      'Alarm',
      'Your alarm is ringing!',
      scheduledTime,
      platformChannelSpecifics,
    );
    setState(() {
      activeAlarms.add(id);
    });
  }

  Future<void> cancelAlarm(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    setState(() {
      activeAlarms.remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Alarm Manager')),
      body: Column(
        children: [
          ElevatedButton(
            child: Text('Set Alarm'),
            onPressed: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(Duration(days: 365)),
              );
              if (pickedDate != null) {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  DateTime scheduledTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                  // For simplicity, we're using a fixed tune. You can add a dropdown to select different tunes.
                  await scheduleAlarm(scheduledTime, 'alarm_sound');
                }
              }
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: activeAlarms.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Alarm ${activeAlarms[index]}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => cancelAlarm(activeAlarms[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}