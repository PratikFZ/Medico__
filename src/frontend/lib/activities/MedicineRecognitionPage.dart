// ignore_for_file: use_build_context_synchronously, file_names

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:medico/activities/MedicineInfo';
import 'package:medico/activities/SchedulesPage.dart';
import 'package:medico/functions/function.dart';

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
  // ignore: unused_field
  String _extractedText = "";
  List<MedicineInfo> _medicineDetails = [];

  Future<void> _pickImageFromGal() async {
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

  Future<void> _pickImageFromCam() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);

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

    String url = '${getLink()}/process_image'; // Update with your server IP

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
      } else {
        var errorData = jsonDecode(response.body);
        showError(errorData['error'] ?? 'Unknown error occurred', context);
      }
    } catch (e) {
      showError('Failed to connect to ocr server: $e', context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                  if (med.quantity.isNotEmpty)
                    Text('Quantity: ${med.quantity}'),
                  if (med.duration.isNotEmpty)
                    Text('Duration: ${med.duration}'),
                  if (med.meal.isNotEmpty) Text('Meal: ${med.meal}'),
                  if (med.frequency.isNotEmpty)
                    Text('Frequency: ${med.frequency}'),
                ],
              ),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () async {
                    final MedicineInfo? save = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditSchedulePage(
                          medicineInfo: med,
                          isSave: false,
                        ),
                      ),
                    );
                    if (save != null) {
                      setState(() {
                        _medicineDetails[index] = save;
                      });
                    }
                  },
                ),
                IconButton(
                  onPressed: () async {
                    saveScheduleLocally(med, context);
                  },
                  icon: Icon(Icons.save),
                )
              ])),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image == null
                ? Text('No image selected.')
                : Image.file(
                    _image!,
                    height: 200,
                  ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget> [
                ElevatedButton.icon(
                  onPressed: _pickImageFromGal,
                  icon: Icon(Icons.image),
                  label: Text('Pick Image'),
                ),
                ElevatedButton.icon(
                  onPressed: _pickImageFromCam,
                  icon: Icon(Icons.camera),
                  label: Text('Pick Image'),
                ),
              ]
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // if (_extractedText.isNotEmpty) ...[
                      //   Text(
                      //     'Extracted Text:',
                      //     style: TextStyle(
                      //         fontWeight: FontWeight.bold, fontSize: 16),
                      //   ),
                      //   SizedBox(height: 8),
                      //   Text(_extractedText),
                      //   SizedBox(height: 20),
                      // ],
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
