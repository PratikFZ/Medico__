// MedicineCard remains the same as in the previous implementation
import 'package:medico_/activities/MedicineInfo.dart';
import 'package:flutter/material.dart';
import 'package:medico_/functions/function.dart';
import 'package:medico_/functions/alarm.dart';

class MedicineCard extends StatefulWidget {
  final MedicineInfo med;

  const MedicineCard({
    super.key,
    required this.med,
  });

  @override
  MedicineCardWidget createState() => MedicineCardWidget();
}

class MedicineCardWidget extends State<MedicineCard> {
  bool switchValue = true;
  String getTime(DateTime? time) {
    if (time == null) return 'null';
    String hrs = time.hour.toString();
    String min = time.minute.toString();

    return "$hrs : $min";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.medical_services,
                color: Colors.blueAccent, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.med.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.med.quantity,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  getTime(getLatestTimeOfAlarm(widget.med)),
                  style:
                      const TextStyle(fontSize: 14, color: Colors.blueAccent),
                ),
                const SizedBox(height: 8),
                Switch(
                  value: switchValue,
                  onChanged: (value) {
                    // Handle toggle logic here
                    setState(() {
                      switchValue = value;
                    });
                    if (!value) {
                      deleteAlarm(widget.med.id);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
