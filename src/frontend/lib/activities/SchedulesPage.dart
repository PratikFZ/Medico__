// ignore_for_file: file_names, use_build_context_synchronously

import 'dart:convert';

// import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:medico_/activities/MedicineInfo.dart';
import 'package:medico_/functions/function.dart';
// import 'package:http/http.dart' as http;
import 'package:medico_/functions/genTTS.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medico_/activities/EditSchedule.dart';

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  SchedulesPageState createState() => SchedulesPageState();
}

class SchedulesPageState extends State<SchedulesPage> {
  // ignore: prefer_final_fields
  List<MedicineInfo> _schedules = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // _fetchSchedules();
    _fetchSchedulesLocally(context);
  }

  // Future<void> _fetchSchedulesLocally( BuildContext context ) async {
  //     _schedules = await fetchSchedules(context) ;
  // }
  Future<void> _fetchSchedulesLocally(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _schedules.clear();
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('medicine_')) {
          final String? medicineJson = prefs.getString(key);
          if (medicineJson != null) {
            final data = jsonDecode(medicineJson);
            _schedules.add(MedicineInfo.fromJson(data));
          }
        }
      }

      // await generateTTS(_schedules, context);
    } catch (e) {
      showError('Failed to fetch schedules locally: $e', context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Future<void> _fetchSchedules() async {
  //   setState(() {
  //     _isLoading = true;
  //   });

  //   String url = '${getLink()}/schedules'; // Update with your server IP

  //   try {
  //     var response = await http.get(Uri.parse(url));

  //     if (response.statusCode == 200) {
  //       var data = jsonDecode(response.body);
  //       setState(() {
  //         _schedules = (data as List)
  //             .map((item) => MedicineInfo.fromJson(item))
  //             .toList();
  //       });
  //       await generateTTS(_schedules, context);
  //     } else {
  //       showError('Fails to load data', context);
  //     }
  //   } catch (e) {
  //     showError('Failed to connect to server: $e', context);
  //     // Navigator.of(context).pop();
  //   } finally {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }

  // // ignore: unused_element
  // Future<void> _deleteSchedule(MedicineInfo medicine) async {
  //   setState(() {
  //     _isLoading = true;
  //   });

  //   String url = '${getLink()}/schedules'; // Replace with your server's IP

  //   try {
  //     var response = await http.post(
  //       Uri.parse(url),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({
  //         'operation': 'delete',
  //         'id': medicine.id,
  //       }),
  //     );

  //     if (response.statusCode != 200) {
  //       showError('Failed to delete the entry', context);
  //     }
  //   } catch (e) {
  //     showError('Failed to connect to server: $e', context);
  //   } finally {
  //     setState(() {
  //       _isLoading = false;
  //       _fetchSchedules();
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(100.0),
          child: AppBar(
            title: Text('Schedules'),
            backgroundColor: const Color.fromARGB(255, 35, 227, 153),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
          )),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditSchedulePage(
                isSave: true,
              ),
            ),
          ).then((_) => _fetchSchedulesLocally(context));
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
                  onPressed: () {
                    playTTS(schedule, context);
                  },
                  icon: Icon(Icons.music_note),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    // _deleteSchedule(schedule);
                    deleteScheduleLocally(schedule, context);
                    // await Future.delayed(Duration(seconds: 1), () {});
                    _fetchSchedulesLocally(context);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditSchedulePage(
                            medicineInfo: schedule, isSave: true),
                      ),
                    ).then((_) => fetchSchedulesLocally(context));
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
