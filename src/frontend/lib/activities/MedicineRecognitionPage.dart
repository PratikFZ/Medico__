// ignore_for_file: use_build_context_synchronously, file_names

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:universal_io/io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:medico/activities/MedicineInfo.dart';
import 'package:medico/activities/EditSchedule.dart';
import 'package:medico/functions/function.dart';

class MedicineRecognitionPage extends StatefulWidget {
  const MedicineRecognitionPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MedicineRecognitionPageState createState() =>
      _MedicineRecognitionPageState();
}

class _MedicineRecognitionPageState extends State<MedicineRecognitionPage> {
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  // ignore: unused_field
  String _extractedText = "";
  List<MedicineInfo> _medicineDetails = [];
  
  // Helper method to get the appropriate image widget based on platform
  Future<Widget> _getImageWidget() async {
    if (_image == null) {
      return const Text('No image selected.');
    }
    
    if (kIsWeb) {
      // For web, we need to use a different approach
      // Get the bytes and convert to memory image
      final bytes = await _image!.readAsBytes();
      return Image.memory(
        bytes,
        height: 200,
      );
    } else {
      // For mobile platforms
      return Image.file(
        File(_image!.path),
        height: 200,
      );
    }
  }

  Future<void> _pickImageFromGal() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
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
        _image = pickedFile;
        _extractedText = "";
        _medicineDetails = [];
      });

      await _processImage(_image!);
    }
  }

  Future<void> _processImage(XFile imageFile) async {
    setState(() {
      _isLoading = true;
    });

    String url = '${getLink()}/process_image'; // Update with your server IP

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Handle file upload differently for web and mobile
      if (kIsWeb) {
        // For web, read the bytes directly
        List<int> bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: imageFile.name,
          ),
        );
      } else {
        // For mobile, use fromPath as before
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

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
      return const Text('No medicines recognized.');
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
                  if (med.duration != -1)
                    Text('Duration: ${med.duration}'),
                  if (med.meal.isNotEmpty) Text('Meal: ${med.meal}'),
                  if (med.frequency.isNotEmpty)
                    Text('Frequency: ${med.frequency}'),
                ],
              ),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final MedicineInfo? save = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditPage(
                          medicineInfo: med,
                          // isSave: false,
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
                  icon: const Icon(Icons.save),
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
          title: const Text('Upload Prescription'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _image == null
                    ? const Text('No image selected.')
                    : FutureBuilder<Widget>(
                        future: _getImageWidget(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done && 
                              snapshot.hasData) {
                            return snapshot.data!;
                          } else {
                            return const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                        },
                      ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton.icon(
                      onPressed: _pickImageFromGal,
                      icon: const Icon(Icons.image),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 16), // Add space between buttons
                    ElevatedButton.icon(
                      onPressed: _pickImageFromCam,
                      icon: const Icon(Icons.camera),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
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
                          const Text(
                            'Medicine Details:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          _buildMedicineList(),
                        ],
                      ),
              ],
            ),
          ),
        ));
  }
}