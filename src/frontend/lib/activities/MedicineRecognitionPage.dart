// ignore: duplicate_ignore
// ignore: file_names
// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:medico/activities/MedicineInfo';
import 'package:medico/activities/SchedulesPage.dart';
import 'package:medico/main.dart';
import 'package:path_provider/path_provider.dart';

class MedicineRecognitionPage extends StatefulWidget {
  const MedicineRecognitionPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MedicineRecognitionPageState createState() =>
      _MedicineRecognitionPageState();
}

class _MedicineRecognitionPageState extends State<MedicineRecognitionPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String _extractedText = "";
  List<MedicineInfo> _medicineDetails = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _extractedText = "";
        _medicineDetails = [];
      });

      await _processImage(_image!);
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _isLoading = true;
    });

    String url =
        'http://192.168.1.109:5000/process_image'; // Update with your server IP

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List<dynamic> medicineList = data['medicine_details'];
        String extractedText = data['extracted_text'] ?? "";

        setState(() {
          _extractedText = extractedText;
          _medicineDetails =
              medicineList.map((item) => MedicineInfo.fromJson(item)).toList();
        });

        if (_medicineDetails.isNotEmpty) {
          await _generateTTS(_medicineDetails[0]);
        }
      } else {
        var errorData = jsonDecode(response.body);
        _showError(errorData['error'] ?? 'Unknown error occurred');
      }
    } catch (e) {
      _showError('Failed to connect to ocr server: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateTTS(MedicineInfo medicine) async {
    setState(() {
      _isLoading = true;
    });

    String url =
        'http://192.168.1.109:5000/generate_audio'; // Replace with your server's IP

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': medicine.name,
          'dosage': medicine.quantity.isNotEmpty ? medicine.quantity : '500 mg',
          'meal': medicine.meal.isNotEmpty ? medicine.meal : 'anytime',
        }),
      );

      if (response.headers['content-type']?.contains('text/html') ?? false) {
        _showError("Server returned an unexpected HTML response.");
      }

      if (response.statusCode == 200) {
        // Use pathprovider to get the app's documents directory
        Directory appDocDir = await getApplicationDocumentsDirectory();
        String filePath =
            '${appDocDir.path}/${medicine.name}${medicine.quantity}.mp3';

        // Save the response as an MP3 file
        File audioFile = File(filePath);
        await audioFile.writeAsBytes(
            response.bodyBytes); // Save binary data as a local MP3 file

        // Play the audio file using audioplayers
        // await _audioPlayer.play(DeviceFileSource(audioFile.path));  // Use DeviceFileSource to play local files
        if (await audioFile.exists()) {
          await _audioPlayer.play(DeviceFileSource(audioFile.path));
        } else {
          _showError('Audio file not found');
        }
      } else {
        var errorData = jsonDecode(response.body);
        _showError(errorData['error'] ?? 'Failed to generate TTS');
      }
    } catch (e) {
      _showError('Failed to connect to server: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
            child: Text('OK'),
          )
        ],
      ),
    );
  }

  Widget _buildMedicineList() {
    if (_medicineDetails.isEmpty) {
      return Text('No medicines recognized.');
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _medicineDetails.length,
      itemBuilder: (context, index) {
        MedicineInfo med = _medicineDetails[index];
        return Card(
          child: ListTile(
            title: Text(med.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (med.quantity.isNotEmpty) Text('Quantity: ${med.quantity}'),
                if (med.duration.isNotEmpty) Text('Duration: ${med.duration}'),
                if (med.meal.isNotEmpty) Text('Meal: ${med.meal}'),
                if (med.frequency.isNotEmpty)
                  Text('Frequency: ${med.frequency}'),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditSchedulePage(medicineInfo: med),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Prescription'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            _image == null
                ? Text('No image selected.')
                : Image.file(
                    _image!,
                    height: 200,
                  ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.image),
              label: Text('Pick Image'),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_extractedText.isNotEmpty) ...[
                        Text(
                          'Extracted Text:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(_extractedText),
                        SizedBox(height: 20),
                      ],
                      Text(
                        'Medicine Details:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      _buildMedicineList(),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
