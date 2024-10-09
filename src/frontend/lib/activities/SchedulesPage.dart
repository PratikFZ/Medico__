// ignore_for_file: file_names, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medico/activities/MedicineInfo';
import 'package:medico/functions/function.dart';

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  SchedulesPageState createState() => SchedulesPageState();
}

class SchedulesPageState extends State<SchedulesPage> {
  List<MedicineInfo> _schedules = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchSchedules();
  }

  Future<void> fetchSchedules() async {
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
        showError('Fails to load data', context);
      }
    } catch (e) {
      showError('Failed to connect to server: $e', context);
      // Navigator.of(context).pop();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSchedule(MedicineInfo medicine) async {
    setState(() {
      _isLoading = true;
    });

    String url =
        'http://192.168.1.109:5000/schedules'; // Replace with your server's IP

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'operation': 'delete',
          'name': medicine.name,
        }),
      );

      if (response.statusCode != 200) {
        showError('Failed to delete the entry', context);
      }
    } catch (e) {
      showError('Failed to connect to server: $e', context);
    } finally {
      setState(() {
        _isLoading = false;
        fetchSchedules();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedules'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditSchedulePage(),
            ),
          ).then((_) => fetchSchedules());
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_schedules.isEmpty) {
      return Center(child: Text('No schedules available'));
    }

    return ListView.builder(
      itemCount: _schedules.length,
      itemBuilder: (context, index) {
        if (index >= _schedules.length) {
          return null; // Return null for invalid indices
        }
        MedicineInfo schedule = _schedules[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: Text(schedule.name.isNotEmpty ? schedule.name[0] : '0'),
            ),
            title: Text(
              schedule.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${schedule.quantity} ${schedule.frequency}'),
            // children:
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _deleteSchedule(schedule);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditSchedulePage(medicineInfo: schedule),
                      ),
                    ).then((_) => fetchSchedules());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class EditSchedulePage extends StatefulWidget {
  final MedicineInfo? medicineInfo;

  const EditSchedulePage({super.key, this.medicineInfo});

  @override
  // ignore: library_private_types_in_public_api
  EditSchedulePageState createState() => EditSchedulePageState();
}

class EditSchedulePageState extends State<EditSchedulePage> {
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
    String url =
        'http://192.168.1.109:5000/schedules'; // Replace with your server's IP

    // showError('Failed to save schedule', context);
    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'operation': 'save',
          'name': _nameController.text,
          'quantity': _quantityController.text,
          'frequency': _frequencyController.text,
          'duration': _durationController.text,
          'meal': _mealController.text,
        }),
      );

      if (response.statusCode != 200) {
        showError('Failed to save schedule', context);
      }
    } catch (e) {
      showError('Failed to connect to server: $e', context);
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
              onPressed: () {
                _saveSchedule();
                Navigator.of(context).pop();
              },
              child: Text(widget.medicineInfo == null
                  ? 'Save Schedule'
                  : 'Edit Schedule'),
            ),
          ],
        ),
      ),
    );
  }
}
