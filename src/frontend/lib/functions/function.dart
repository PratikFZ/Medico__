// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously

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
