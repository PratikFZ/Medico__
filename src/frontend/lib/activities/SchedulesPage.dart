// ignore_for_file: file_names

import 'package:medico/MedicineInfo';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
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
  // ignore: library_private_types_in_public_api
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