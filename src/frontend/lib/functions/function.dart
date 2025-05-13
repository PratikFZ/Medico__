// ignore_for_file: use_build_context_synchronously

import 'package:medico/functions/alarm.dart';
import 'package:medico/functions/genTTS.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medico/activities/MedicineInfo.dart';
import 'dart:math';

int generateRandomString() {
  final random = Random();
  // Generate a 7-digit random number
  return random.nextInt(9000000) + 1000000;
}

String getLink() {
  String localhost = 'https://medico-ja6d.onrender.com';
  return localhost;
}

DateTime? getLatestTimeOfAlarm(MedicineInfo med, BuildContext context) {
  if (med.schedules!.isEmpty || med.duration == -1) {
    deleteScheduleLocally(med, context);
    // fetchSchedulesLocally(context);
    return null;
  }
  DateTime now = DateTime.now();
  for (var alarm in med.schedules!) {
    DateTime cur = Map2DT(alarm['hrs'], alarm['min']);
    if (cur.isAfter(now)) {
      return cur;
    }
  }

  med.duration = med.duration - 1;
  return (med.duration != -1)?Map2DT(med.schedules![0]['hrs'], med.schedules![0]['min'])
      .add(const Duration(days: 1)): null;
}

void showError(String message, BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Error'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        )
      ],
    ),
  );
}

Map<String, dynamic> toJson(MedicineInfo med) {
  return {
    'id': med.id,
    'name': med.name,
    'quantity': med.quantity,
    'frequency': med.frequency,
    'duration': med.duration,
    'meal': med.meal,
    'schedules': med.schedules
  };
}

Future<MedicineInfo> fetchMedLocally(int id) async {
  final prefs = await SharedPreferences.getInstance();
  String json = prefs.getString('medicine_$id')!;
  // print('All keys before deletion: ${json}');
  return MedicineInfo.fromJson(jsonDecode(json));
}

Future<void> saveScheduleLocally(
    MedicineInfo medicine, BuildContext context) async {
  // List<MedicineInfo> schedules = [medicine];

  try {
    final prefs = await SharedPreferences.getInstance();
    final String medicineJson = jsonEncode(toJson(medicine));
    final String key = 'medicine_${medicine.id}';
    await prefs.setString(key, medicineJson);

    String dir = await getDir();

    if (!context.mounted) return;

    DateTime? alarmTime = getLatestTimeOfAlarm(medicine, context);
    alarmTime ??= DateTime.now().add(const Duration(minutes: 1));

    setAlarm(
      id: medicine.id,
      dateTime: alarmTime,
      assetAudioPath: '$dir/${medicine.id}.mp3',
      notificationTitle: medicine.name,
      notificationBody: 'Take ${medicine.quantity} of ${medicine.name}',
      context: context,
    );

    // await generateTTS(schedules, context);
    await genrateTTSLocally(medicine);
  } catch (e) {
    showError('Failed to save schedule locally: $e', context);
  }
}

Future<void> editScheduleLocally(
    MedicineInfo medicine, BuildContext context) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final String medicineJson = jsonEncode(toJson(medicine));
    await prefs.setString('medicine_${medicine.id}', medicineJson);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule updated successfully')),
    );
  } catch (e) {
    showError('Failed to update schedule locally: $e', context);
  }
}

Future<void> deleteScheduleLocally(
    MedicineInfo medicine, BuildContext context) async {
  // print('Deleting with id: ${medicine.id}');
  try {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'medicine_${medicine.id}';

    // Debugging: Check if the key exists before deleting
    // print('Attempting to delete key: $key');
    // print('All keys before deletion: ${prefs.getKeys()}');

    if (prefs.containsKey(key)) {
      await prefs.remove(key);
      deleteAlarm(medicine.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule not found')),
      );
    }

    // Debugging: Print all keys after deletion
    // print('All keys after deletion: ${prefs.getKeys()}');
  } catch (e) {
    showError('Failed to delete schedule locally: $e', context);
  }
}

Future<List<MedicineInfo>> fetchSchedulesLocally(BuildContext context) async {
  List<MedicineInfo> schedules = [];
  try {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('medicine_')) {
        final String? medicineJson = prefs.getString(key);
        if (medicineJson != null) {
          final medicineMap = jsonDecode(medicineJson);
          schedules.add(MedicineInfo.fromJson(medicineMap));
        }
      }
    }
  } catch (e) {
    showError('Failed to fetch schedules locally: $e', context);
  }
  return schedules;
}
