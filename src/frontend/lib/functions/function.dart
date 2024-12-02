// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously

import 'package:medico/functions/alarm.dart';
import 'package:medico/functions/genTTS.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medico/activities/MedicineInfo';
import 'package:http/http.dart' as http;

String getLink() {
  String localhost = 'https://sensible-mastiff-intent.ngrok-free.app';
  return localhost;
}

void showError(String message, BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Error'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('OK'),
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
  };
}

Future<void> saveSchedule(MedicineInfo medicine, BuildContext context) async {
  String url = '${getLink()}/schedules'; // Replace with your server's IP

  // showError('Failed to save schedule', context);
  try {
    var response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'operation': 'save',
        'id': medicine.id,
        'name': medicine.name,
        'quantity': medicine.quantity,
        'frequency': medicine.frequency,
        'duration': medicine.duration,
        'meal': medicine.meal,
      }),
    );

    if (response.statusCode != 200) {
      showError('Failed to save schedule', context);
    }
  } catch (e) {
    showError('Failed to connect to server: $e', context);
  }
}

Future<void> editSchedule(MedicineInfo medicine, BuildContext context) async {
  String url = '${getLink()}/schedules'; // Replace with your server's IP

  // showError('Failed to save schedule', context);
  try {
    var response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'operation': 'edit',
        'id': medicine.id,
        'name': medicine.name,
        'quantity': medicine.quantity,
        'frequency': medicine.frequency,
        'duration': medicine.duration,
        'meal': medicine.meal,
      }),
    );

    if (response.statusCode != 200) {
      showError('Failed to save schedule', context);
    }
  } catch (e) {
    showError('Failed to connect to server: $e', context);
  }
}

Future<void> deleteSchedule(MedicineInfo medicine, BuildContext context) async {
  String url = '${getLink()}/schedules'; // Replace with your server's IP

  try {
    var response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'operation': 'delete',
        'id': medicine.id,
      }),
    );

    if (response.statusCode != 200) {
      showError('Failed to delete the entry', context);
    }
  } catch (e) {
    showError('Failed to connect to server: $e', context);
  }
}

Future<List<MedicineInfo>> fetchSchedules(BuildContext context) async {
  String url = '${getLink()}/schedules'; // Update with your server IP
  List<MedicineInfo> schedules = [];

  try {
    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      schedules =
          (data as List).map((item) => MedicineInfo.fromJson(item)).toList();
    } else {
      showError('Fails to load data', context);
    }
  } catch (e) {
    showError('Failed to connect to server: $e', context);
    // Navigator.of(context).pop();
  }

  return schedules;
}

Future<void> saveScheduleLocally(
    MedicineInfo medicine, BuildContext context) async {
  List<MedicineInfo> _schedules = [medicine];
  try {
    final prefs = await SharedPreferences.getInstance();
    final String medicineJson = jsonEncode(toJson(medicine));
    await prefs.setString('medicine_${medicine.id}', medicineJson);
    String dir = await getDir();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Schedule saved successfully')),
    );
    await generateTTS(_schedules, context);
    setAlarm(
        id: medicine.id,
        dateTime: DateTime.now().add(Duration(minutes: 1)),
        assetAudioPath: '$dir/${medicine.id}.mp3',
        notificationTitle: medicine.name,
        notificationBody: 'take ${medicine.quantity} of ${medicine.name}',
        context: context);
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
      SnackBar(content: Text('Schedule updated successfully')),
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
      SnackBar(content: Text('Schedule deleted successfully')),
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
