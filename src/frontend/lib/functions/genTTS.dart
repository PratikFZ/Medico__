// ignore_for_file: file_names, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:medico/activities/MedicineInfo.dart';
import 'package:medico/functions/function.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';

Future<String> getDir() async {
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String ttsDir = '${appDocDir.path}/tts_files';
  return ttsDir;
}

Future<void> generateTTS(
    List<MedicineInfo> medicines, BuildContext context) async {
  String url = '${getLink()}/generate_audio'; // Replace with your server's IP

  // Directory appDocDir = await getApplicationDocumentsDirectory();
  // String ttsDir = '${appDocDir.path}/tts_files';
  String ttsDir = await getDir();

  for (final med in medicines) {
    if (await Directory('$ttsDir/${med.id}.mp3').exists()) {
      medicines.remove(med);
      print("removed!!");
    } else {
      print("Fuckedup!!");
    }
  }

  try {
    var response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'medicines': medicines
            .map((medicine) => {
                  'id': medicine.id,
                  'name': medicine.name,
                  'quantity':
                      medicine.quantity.isNotEmpty ? medicine.quantity : '',
                })
            .toList(),
      }),
    );

    if (response.headers['content-type']?.contains('application/zip') ??
        false) {
      // Get the app's documents directory
      // Directory appDocDir = await getApplicationDocumentsDirectory();
      // String ttsDir = '${appDocDir.path}/tts_files';

      // Create the directory if it doesn't exist
      await Directory(ttsDir).create(recursive: true);
      final archive = ZipDecoder().decodeBytes(response.bodyBytes);
      // Extract all the files
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File('$ttsDir/$filename')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        }
      }

      showError('TTS files downloaded and extracted successfully', context);
    } else if (response.statusCode != 200) {
      var errorData = jsonDecode(response.body);
      showError(errorData['error'] ?? 'Failed to generate TTS', context);
    }
  } catch (e) {
    showError('Failed to connect to server: $e', context);
  }
}

// Function to play a specific TTS file
Future<void> playTTS(MedicineInfo medicine, BuildContext context) async {
  final AudioPlayer audioPlayer = AudioPlayer();
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String filePath = '${appDocDir.path}/tts_files/${medicine.id}.mp3';

  File audioFile = File(filePath);
  if (await audioFile.exists()) {
    await audioPlayer.play(DeviceFileSource(audioFile.path));
  } else {
    showError('Audio file not found', context);
  }
}
