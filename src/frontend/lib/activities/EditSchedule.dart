import 'package:flutter/material.dart';
import 'package:medico/activities/MedicineInfo.dart';
import 'package:medico/functions/alarm.dart';
import 'package:medico/functions/function.dart';
// import 'package:medico_/functions/alarm.dart';
// import 'package:http/http.dart' as http;

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
  String _meal = '';
  String _frequency = '';
  // List<TimeOfDay> _alarms = [];
  List<dynamic> schedules = [];
  List<TimeOfDay> alarms = [];

  @override
  void initState() {
    super.initState();
    _medicineName = widget.medicineInfo?.name ?? '';
    _quantity = widget.medicineInfo?.quantity ?? '';
    schedules = widget.medicineInfo?.schedules ?? [];
    alarms = Map2TOD(schedules);
    _duration = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      DateTime.now().hour,
      DateTime.now().minute,
    ).add(Duration(days: widget.medicineInfo?.duration ?? 0 ));
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
          initialValue: widget.medicineInfo?.meal,
          onChanged: (value) {
            setState(() {
              _meal = value;
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
          children: alarms.map((alarm) {
            return ListTile(
              title: Text(alarm.format(context)),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    alarms.remove(alarm);
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
                    alarms[alarms.indexOf(alarm)] = newTime;
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
                alarms.add(newTime);
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

    if (alarms.length == 3) {
      _frequency = 'thrice daily';
    } else if (alarms.length == 2) {
      _frequency = 'twice daily';
    } else if (alarms.length == 1) {
      _frequency = 'once daily';
    } else {
      _frequency = 'custom';
    }

    for (var alarm in alarms) {
      schedules.add({"hrs": alarm.hour, "min": alarm.minute});
    }

    MedicineInfo medicineInfo = MedicineInfo(
      name: _medicineName,
      duration: _duration.difference( DateTime.now()).inDays,
      quantity: _quantity,
      meal: _meal,
      frequency: _frequency,
    );
    medicineInfo.schedules = schedules;

    if (widget.medicineInfo == null) {
      saveScheduleLocally(medicineInfo, context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule saved successfully')),
      );
    }

    Navigator.of(context).pop(medicineInfo);
  }
}
