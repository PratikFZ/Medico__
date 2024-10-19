import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:medico/functions/function.dart';

// Function 1: Initialize alarms
Future<void> initializeAlarms() async {
  await Alarm.init();
}

int strID2intID(String id) {
  List<int> asciiCodes = id.runes.toList();
  int sumOfAsciiCodes = asciiCodes.reduce((a, b) => a + b);

  return sumOfAsciiCodes;
}

// Function 2: Set an alarm
Future<void> setAlarm({
  required String id,
  required DateTime dateTime,
  required String assetAudioPath,
  required String notificationTitle, //Medicine name
  required String notificationBody, //Medicine dosage
  required BuildContext context,
  bool loopAudio = true,
  bool vibrate = true,
  bool fadeDuration = true,
}) async {
  final alarmSettings = AlarmSettings(
    id: strID2intID(id),
    dateTime: dateTime,
    assetAudioPath: assetAudioPath,
    loopAudio: loopAudio,
    vibrate: vibrate,
    fadeDuration: 3.0,
    notificationSettings: NotificationSettings(
      title: notificationTitle,
      body: notificationBody,
    ),
  );
  await Alarm.set(alarmSettings: alarmSettings);
  // ignore: use_build_context_synchronously
  showError("Alarm set at $dateTime", context);
}

void handleAlarm(BuildContext context, int id) {
  Alarm.ringStream.stream.listen((_) {
    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alarm'),
        content: Text('Your alarm is ringing!'),
        actions: [
          TextButton(
            onPressed: () {
              Alarm.stop(id);
              Navigator.pop(context);
            },
            child: Text('Dismiss'),
          ),
        ],
      ),
    );
  });
}

// Function 4: Delete an alarm
Future<void> deleteAlarm( String id) async {
  await Alarm.stop( strID2intID(id) );
}

// Function 5: Get all alarms
Future<List<AlarmSettings>> getAlarms() async {
  return Alarm.getAlarms();
}
