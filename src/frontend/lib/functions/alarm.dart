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

Future<void> setAlarm({
  required int id,
  required DateTime dateTime,
  required String assetAudioPath,
  required String notificationTitle,
  required String notificationBody,
  required BuildContext context,
  bool loopAudio = true,
  bool vibrate = true,
  bool fadeDuration = true,
}) async {
  try {
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: assetAudioPath,
      loopAudio: loopAudio,
      vibrate: vibrate,
      volume: 1,
      volumeEnforced: true,
      fadeDuration: 3.0,
      notificationSettings: NotificationSettings(
        title: notificationTitle,
        body: notificationBody,
        stopButton: "Stop",
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);

    if (context.mounted) {
      // Show success message instead of error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alarm scheduled for ${dateTime.toString()}'),
          backgroundColor:
              Colors.green, // Optional: makes it visually distinct from errors
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      showError("Failed to set alarm: $e", context);
    }
  }
}

void handleAlarm(BuildContext context, int id) {
  Alarm.ringStream.stream.listen((_) {
    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alarm'),
        content: const Text('Your alarm is ringing!'),
        actions: [
          TextButton(
            onPressed: () {
              Alarm.stop(id);
              Navigator.pop(context);
            },
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  });
}

// Function 4: Delete an alarm
Future<void> deleteAlarm(int id) async {
  await Alarm.stop(id);
}

// Function 5: Get all alarms
Future<List<AlarmSettings>> getAlarms() async {
  return Alarm.getAlarms();
}

DateTime TOD2DT(TimeOfDay t) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, t.hour, t.minute);
}

DateTime Map2DT(int hrs, int min) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, hrs, min);
}

List<TimeOfDay> Map2TOD(List<dynamic> alarms) {
  List<TimeOfDay> alarmsTOD = [];
  for (var alarm in alarms) {
    alarmsTOD.add( TimeOfDay(hour: alarm['hrs'], minute: alarm['min']) );
  }
  return alarmsTOD;
}
