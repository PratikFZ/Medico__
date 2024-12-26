// ignore: duplicate_ignore
// ignore: file_names
// ignore_for_file: file_names

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:medico/activities/MedicineInfo.dart';
import 'package:medico/functions/function.dart';

// ignore: must_be_immutable
class AlarmRingScreen extends StatefulWidget {
  AlarmSettings alarmSettings;
  MedicineInfo med;
  AlarmRingScreen({required this.alarmSettings, required this.med, super.key});

  @override
  // ignore: library_private_types_in_public_api
  AlarmRingScreenState createState() => AlarmRingScreenState();
}

class AlarmRingScreenState extends State<AlarmRingScreen> {

  @override
  void initState() {
    super.initState();
    // _initialize();
  }

  // Future<void> _initialize() async {
  //   // widget.med = await fetchMedLocally(widget.alarmSettings.id);
  //   // setState(() {}); // Trigger a rebuild once the data is fetched
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              'You alarm (${ widget.med.name}) is ringing...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text('🔔', style: TextStyle(fontSize: 50)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                RawMaterialButton(
                  onPressed: () {
                    final now = DateTime.now();
                    Alarm.set(
                      alarmSettings: widget.alarmSettings.copyWith(
                        dateTime: DateTime(
                          now.year,
                          now.month,
                          now.day,
                          now.hour,
                          now.minute,
                        ).add(const Duration(minutes: 1)),
                      ),
                    ).then((_) {
                      if (context.mounted) Navigator.pop(context);
                    });
                  },
                  child: Text(
                    'Snooze',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                RawMaterialButton(
                  onPressed: () {
                    // Alarm.stop(widget.alarmSettings.id).then((_) {
                    //   if (context.mounted) Navigator.pop(context);
                    // });
                    Alarm.set(
                      alarmSettings: widget.alarmSettings.copyWith(
                        dateTime: getLatestTimeOfAlarm( widget.med ) ,
                      ),
                    ).then((_) {
                      if (context.mounted) Navigator.pop(context);
                    });
                  },
                  child: Text(
                    'Stop',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
