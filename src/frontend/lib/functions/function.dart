// ignore_for_file: use_build_context_synchronously

import 'package:medico_/functions/alarm.dart';
import 'package:medico_/functions/genTTS.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medico_/activities/MedicineInfo.dart';
import 'dart:math';

String generateRandomString() {
  const characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  final random = Random();
  return List.generate(
      7, (index) => characters[random.nextInt(characters.length)]).join();
}

String getLink() {
  String localhost = 'https://sensible-mastiff-intent.ngrok-free.app';
  return localhost;
}

DateTime? getLatestTimeOfAlarm(MedicineInfo med) {
  if (med.schedules!.isEmpty) {
    return null;
  }
  DateTime now = DateTime.now();
  for (var alarm in med.schedules!) {
    DateTime cur = Map2DT(alarm['hrs'], alarm['min']);
    if (cur.isAfter(now)) {
      return cur;
    }
  }
  return Map2DT(med.schedules![0]['hrs'], med.schedules![0]['min']);
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

Future<void> saveScheduleLocally(
    MedicineInfo medicine, BuildContext context) async {
  List<MedicineInfo> schedules = [medicine];
  try {
    final prefs = await SharedPreferences.getInstance();
    final String medicineJson = jsonEncode(toJson(medicine));
    // print(medicineJson);
    await prefs.setString('medicine_${medicine.id}', medicineJson);
    String dir = await getDir();

    if (!context.mounted) return;

    DateTime? alarmTime = getLatestTimeOfAlarm(medicine);
    alarmTime ??= DateTime.now().add(const Duration(minutes: 1));

    setAlarm(
        id: medicine.id,
        dateTime: alarmTime, //DateTime.now().add(const Duration(minutes: 1)),
        assetAudioPath: '$dir/${medicine.id}.mp3',
        notificationTitle: medicine.name,
        notificationBody: 'take ${medicine.quantity} of ${medicine.name}',
        context: context);
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(content: Text('Schedule saved successfully')),
    // );

    await generateTTS(schedules, context);

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
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('medicine_${medicine.id}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule deleted successfully')),
    );
    deleteAlarm(medicine.id);
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
