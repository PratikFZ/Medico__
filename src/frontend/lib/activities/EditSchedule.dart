import 'package:flutter/material.dart';
import 'package:medico/activities/MedicineInfo.dart';
import 'package:medico/functions/function.dart';
// import 'package:medico_/functions/alarm.dart';
// import 'package:http/http.dart' as http;

class EditSchedulePage extends StatefulWidget {
  final MedicineInfo? medicineInfo;
  final bool isSave;

  const EditSchedulePage({super.key, this.medicineInfo, required this.isSave});

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

  MedicineInfo fetchChanges() {
    return MedicineInfo(
      id: widget.medicineInfo == null ? 'x0' : widget.medicineInfo!.id,
      name: _nameController.text,
      quantity: _quantityController.text,
      frequency: _frequencyController.text,
      duration: _durationController.text,
      meal: _mealController.text,
    );
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
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Medicine Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a medicine name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            TextFormField(
              controller: _frequencyController,
              decoration: const InputDecoration(labelText: 'Frequency'),
            ),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(labelText: 'Duration'),
            ),
            TextFormField(
              controller: _mealController,
              decoration: const InputDecoration(labelText: 'Meal'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (widget.isSave) {
                  if (widget.medicineInfo == null) {
                    saveScheduleLocally(
                      fetchChanges(),
                      context,
                    );
                  } else {
                    editScheduleLocally(
                      fetchChanges(),
                      context,
                    );
                  }
                }
                Navigator.of(context).pop(fetchChanges());
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

class EditPage extends StatefulWidget {
  final MedicineInfo? medicineInfo;
  const EditPage({super.key, this.medicineInfo});
  @override
  // ignore: library_private_types_in_public_api
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  String _medicineName = '';
  final List<bool> _selectedDays = List.generate(7, (_) => false);
  DateTime _duration = DateTime.now();
  String _quantity = '';
  final String _meal = '';
  String _frequency = '';
  final List<TimeOfDay> _alarms = [];
  List<dynamic> schedules = [];

  @override
  void initState() {
    super.initState();
    _medicineName = widget.medicineInfo?.name ?? '';
    _quantity = widget.medicineInfo?.quantity ?? '';
    schedules;
    _duration = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      DateTime.now().hour,
      DateTime.now().minute,
    ).add(const Duration(days: 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back
            Navigator.of(context).pop();
          },
        ),
        title: Text(
            widget.medicineInfo == null ? 'Add Schedule' : 'Edit Schedule'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameSection(),
              const SizedBox(height: 16.0),
              _buildDosageSection(),
              const SizedBox(height: 16.0),
              _buildSpecialNotesSection(),
              const SizedBox(height: 16.0),
              _buildAlarmSection(),
              const SizedBox(height: 16.0),
              _buildDaysSection(),
              const SizedBox(height: 16.0),
              _buildDurationSection(),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _saveReminder,
                child: const Text('Save Reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Medicine name'),
        const SizedBox(height: 8.0),
        TextFormField(
          initialValue: _medicineName,
          onChanged: (value) {
            setState(() {
              _medicineName = value;
            });
          },
          decoration: const InputDecoration(
            hintText: 'Paracetamol/Avil',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildDosageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Medicine dosage'),
        const SizedBox(height: 8.0),
        TextFormField(
          initialValue: widget.medicineInfo?.quantity,
          onChanged: (value) {
            setState(() {
              _quantity = value;
            });
          },
          decoration: const InputDecoration(
            hintText: '5 ml/2 tab',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Meal'),
        const SizedBox(height: 8.0),
        TextFormField(
          // maxLines: 3,
          initialValue: widget.medicineInfo?.quantity,
          onChanged: (value) {
            setState(() {
              _quantity = value;
            });
          },
          decoration: const InputDecoration(
            hintText: 'After dinner',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildAlarmSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Set Alarm'),
        const SizedBox(height: 8.0),
        Column(
          children: _alarms.map((alarm) {
            return ListTile(
              title: Text(alarm.format(context)),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _alarms.remove(alarm);
                  });
                },
              ),
              onTap: () async {
                final newTime = await showTimePicker(
                  context: context,
                  initialTime: alarm,
                );
                if (newTime != null) {
                  setState(() {
                    _alarms[_alarms.indexOf(alarm)] = newTime;
                  });
                }
              },
            );
          }).toList(),
        ),
        ElevatedButton(
          onPressed: () async {
            final newTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (newTime != null) {
              setState(() {
                _alarms.add(newTime);
              });
            }
          },
          child: const Text('Add Alarm'),
        ),
      ],
    );
  }

  Widget _buildDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Days'),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          children: [
            for (int i = 0; i < 7; i++)
              ChoiceChip(
                label: Text(['S', 'M', 'T', 'W', 'T', 'F', 'S'][i]),
                selected: _selectedDays[i],
                onSelected: (value) {
                  setState(() {
                    _selectedDays[i] = value;
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Duration'),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () async {
                  final newDate = await showDatePicker(
                    context: context,
                    initialDate: _duration,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 1000)),
                  );
                  if (newDate != null) {
                    setState(() {
                      _duration = newDate;
                    });
                  }
                },
                child: Text(
                    '${_duration.month}/${_duration.day}/${_duration.year}'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Set duration
              },
              child: const Text('Set Duration'),
            ),
          ],
        ),
      ],
    );
  }

  void _saveReminder() {
    // Save the reminder data and navigate back

    if (_alarms.length == 3) {
      _frequency = 'thrice daily';
    } else if (_alarms.length == 2) {
      _frequency = 'twice daily';
    } else if (_alarms.length == 1) {
      _frequency = 'once daily';
    } else {
      _frequency = 'custom';
    }

    for (var alarm in _alarms) {
      // print('All good');
      schedules.add({"hrs": alarm.hour, "min": alarm.minute});
    }

    MedicineInfo medicineInfo = MedicineInfo(
      name: _medicineName,
      quantity: _quantity,
      meal: _meal,
      frequency: _frequency,
    );
    medicineInfo.schedules = schedules;

    saveScheduleLocally(medicineInfo, context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule saved successfully')),
    );

    Navigator.pop(context);
  }
}
