// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medico/activities/EditSchedule.dart';
import 'package:medico/activities/SchedulesPage.dart';
import 'package:medico/functions/function.dart';
import 'package:medico/activities/MedicineInfo.dart';
import 'package:medico/activities/AlaramRingPage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medico/activities/MedicineRecognitionPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alarm/alarm.dart';
import 'package:medico/materials/medicineCard.dart';
import 'dart:async';
import 'package:medico/functions/alarm.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<MedicineInfo> medicineSchedule = [];
  // ignore: unused_field
  bool _isLoading = false;

  late List<AlarmSettings>? alarms = [];

  static StreamSubscription<AlarmSettings>? ringSubscription;
  static StreamSubscription<int>? updateSubscription;

  @override
  void initState() {
    super.initState();
    _fetchSchedulesLocally(context);
    initializeAlarms();
    loadAlarms();
    ringSubscription ??= Alarm.ringStream.stream.listen(navigateToRingScreen);
    updateSubscription ??= Alarm.updateStream.stream.listen((_) {
      loadAlarms();
    });
  }

  void loadAlarms() {
    setState(() {
      alarms ??= Alarm.getAlarms() as List<AlarmSettings>?;
      alarms?.sort((a, b) => a.dateTime.isBefore(b.dateTime) ? 0 : 1);
    });
  }

  Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AlarmRingScreen(alarmSettings: alarmSettings),
      ),
    );
    loadAlarms();
  }

  @override
  void dispose() {
    ringSubscription?.cancel();
    updateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchSchedulesLocally(BuildContext context) async {
    setState(() {
      _isLoading = true;
      medicineSchedule.clear();
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('medicine_')) {
          final String? medicineJson = prefs.getString(key);
          if (medicineJson != null) {
            final data = jsonDecode(medicineJson);
            medicineSchedule.add(MedicineInfo.fromJson(data));
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

  final List<Map<String, String>> newsUpdates = [
    {
      "title": "Healthy Aging India",
      "description": "events all around talking about healthy aging",
      "url": "https://healthyagingindia.org/events/"
    },
    {
      "title": "Epoch Elder Care",
      "description":
          "Premium care facility homes in Pune and Gurugram for elders whose families are based in India or abroad.",
      "url": "https://www.epocheldercare.com/epoch-events"
    },
    {
      "title": "Ayurvedic Wellness Retreat",
      "description":
          "21 Day Senior's Wellness Retreat in Karnataka, India with Ayurvedic Consultations and Treatment",
      "url":
          "https://www.bookyogaretreats.com/retreats-for-women-india/21-day-senior-s-wellness-retreat-in-somwarpet-karnataka-with-ayurvedic-consultations-and-treatment"
    },
  ];

  // Method to handle bottom navigation item taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: const ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Manually add the entry'),
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const EditPage()) //MedicineRecognitionPage()),
                        ).then((_) => _fetchSchedulesLocally(context));
                  },
                ),
                const Divider(),
                GestureDetector(
                  child: const ListTile(
                    leading: Icon(Icons.photo_camera),
                    title: Text('Scan the perscription'),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const MedicineRecognitionPage()),
                    ).then((_) => _fetchSchedulesLocally(context));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String grettenigMsg() {
    final int time = DateTime.now().hour;
    if (time >= 4 && time < 12) {
      return "Good Morning, Champ";
    } else if (time >= 12 && time < 16) {
      return "Good Afternoon, Champ";
    } else if (time >= 16 && time < 22) {
      return "Good Evening, Champ";
    }
    return "Go to sleep Champ!";
  }

  // Method to get the current page based on selected index
  Widget _getCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildMedicinesPage();
      case 2:
        return const SchedulesPage();
      default:
        return _buildHomePage();
    }
  }

  // Home page content (similar to previous implementation)
  Widget _buildHomePage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Upcoming Reminders"),
          Expanded(
              child: medicineSchedule.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "No data, please add schedule",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: medicineSchedule.length,
                      itemBuilder: (context, index) {
                        final medicine = medicineSchedule[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Dismissible(
                            key: ValueKey(medicine
                                .id), // Use a unique key, such as the medicine ID
                            direction: DismissDirection
                                .horizontal, // Allow horizontal swiping
                            onDismissed: (direction) {
                              // Perform action when dismissed, e.g., remove item from list
                              setState(() {
                                deleteScheduleLocally(medicine, context);
                                medicineSchedule.removeAt(index);
                              });
                            },
                            child: MedicineCard(
                              med: medicine, // medicine['time']!,
                            ),
                          ),
                        );
                      },
                    )

              // : ListView.builder(
              //     itemCount: medicineSchedule.length,
              //     itemBuilder: (context, index) {
              //       final medicine = medicineSchedule[index];

              //       return Padding(
              //         padding: const EdgeInsets.symmetric(vertical: 8.0),
              //         child: MedicineCard(
              //           med: medicine, //medicine['time']!, //
              //         ),
              //       );
              //     },
              //   ),
              ),
          GestureDetector(
            onTap: () {
              // print("Add Schedule tapped!");
              // _showImageSourceDialog();
              _showImageSourceDialog();
            },
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Center(
                child: Text(
                  "Add Schedule",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Text(
              "Updates & News",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: newsUpdates.length,
              itemBuilder: (context, index) {
                final news = newsUpdates[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: SingleChildScrollView(
                      child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            news["title"]!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            news["description"]!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final Uri uri = Uri.parse(news["url"]!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              } else {
                                // Handle error: URL can't be launched
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Could not open the URL')),
                                );
                              }
                            },
                            child: const Text('Learn more >'),
                          ),
                        ],
                      ),
                    ),
                  )),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // Placeholder pages for other bottom navigation items
  Widget _buildMedicinesPage() {
    return Center(
      child: Text(
        'Medicines Page',
        style: TextStyle(fontSize: 24, color: Colors.blue[700]),
      ),
    );
  }

  Widget _buildProfilePage() {
    return Center(
      child: Text(
        'Profile Page',
        style: TextStyle(fontSize: 24, color: Colors.blue[700]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50.0),
              child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    grettenigMsg(),
                    style: const TextStyle(
                      color: Color(0xff000000),
                      fontSize: 22,
                    ),
                  )))),
      body: _getCurrentPage(), // Use the method to display current page
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.home),
              color: _selectedIndex == 0 ? Colors.blue : Colors.grey,
              onPressed: () {
                _onItemTapped(0);
              },
            ),
            const SizedBox(width: 60),
            IconButton(
              icon: const Icon(Icons.settings),
              color: _selectedIndex == 2 ? Colors.blue : Colors.grey,
              onPressed: () {
                _onItemTapped(2);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add your button functionality here
        },
        backgroundColor: Colors.blue,
        shape: const CircleBorder(),
        elevation: 8.0,
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
