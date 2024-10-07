// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicine Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medicine Manager'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MedicineRecognitionPage()),
                );
              },
              child: Text('Upload Prescription'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SchedulesPage()),
                );
              },
              child: Text('View Schedules'),
            ),
          ],
        ),
      ),
    );
  }
}

class MedicineRecognitionPage extends StatefulWidget {
  const MedicineRecognitionPage({super.key});

  @override
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

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }
  
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

  Future<void> _checkConnection() async {
    String url = 'http://192.168.1.109:5000/ping';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      _showError(":( Failed to connect to the server");
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
          'medicine_name': medicine.name,
          'dosage': medicine.quantity.isNotEmpty ? medicine.quantity : '500 mg',
          // 'meal': medicine.meal.isNotEmpty ? medicine.meal : 'anytime',
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
            onPressed: () => Navigator.of(ctx).pop(),
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

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  _SchedulesPageState createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage> {
  List<MedicineInfo> _schedules = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    setState(() {
      _isLoading = true;
    });

    String url =
        'http://192.168.1.109:5000/schedules'; // Update with your server IP

    try {
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          _schedules = (data as List)
              .map((item) => MedicineInfo.fromJson(item))
              .toList();
        });
      } else {
        _showError('Failed to fetch schedules');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedules'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _schedules.length,
              itemBuilder: (context, index) {
                MedicineInfo schedule = _schedules[index];
                return ListTile(
                  title: Text(schedule.name),
                  subtitle: Text('${schedule.quantity} ${schedule.frequency}'),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditSchedulePage(medicineInfo: schedule),
                        ),
                      ).then((_) => _fetchSchedules());
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditSchedulePage(),
            ),
          ).then((_) => _fetchSchedules());
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class EditSchedulePage extends StatefulWidget {
  final MedicineInfo? medicineInfo;

  const EditSchedulePage({super.key, this.medicineInfo});

  @override
  _EditSchedulePageState createState() => _EditSchedulePageState();
}

class _EditSchedulePageState extends State<EditSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _frequencyController;
  late TextEditingController _durationController;
  late TextEditingController _mealController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.medicineInfo?.name ?? '');
    _quantityController =
        TextEditingController(text: widget.medicineInfo?.quantity ?? '');
    _frequencyController =
        TextEditingController(text: widget.medicineInfo?.frequency ?? '');
    _durationController =
        TextEditingController(text: widget.medicineInfo?.duration ?? '');
    _mealController =
        TextEditingController(text: widget.medicineInfo?.meal ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _mealController.dispose();
    super.dispose();
  }

  Future<void> _saveSchedule() async {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.medicineInfo == null ? 'Add Schedule' : 'Edit Schedule'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Medicine Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a medicine name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: 'Quantity'),
            ),
            TextFormField(
              controller: _frequencyController,
              decoration: InputDecoration(labelText: 'Frequency'),
            ),
            TextFormField(
              controller: _durationController,
              decoration: InputDecoration(labelText: 'Duration'),
            ),
            TextFormField(
              controller: _mealController,
              decoration: InputDecoration(labelText: 'Meal'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSchedule,
              child: Text('Save Schedule'),
            ),
          ],
        ),
      ),
    );
  }
}

class MedicineInfo {
  final String name;
  final String quantity;
  final String duration;
  final String meal;
  final String frequency;

  MedicineInfo({
    required this.name,
    this.quantity = "",
    this.duration = "",
    this.meal = "anytime",
    this.frequency = "",
  });

  factory MedicineInfo.fromJson(Map<String, dynamic> json) {
    return MedicineInfo(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? '',
      duration: json['duration'] ?? '',
      meal: json['meal'] ?? 'anytime',
      frequency: json['frequency'] ?? '',
    );
  }
}
