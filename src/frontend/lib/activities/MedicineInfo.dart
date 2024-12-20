import 'package:medico/functions/function.dart';

class MedicineInfo {
  String id;
  final String name;
  final String quantity;
  final String duration; // in days only
  final String meal;
  final String frequency;
  List<dynamic>? schedules;

  MedicineInfo({
    required this.name,
    this.quantity = "",
    this.duration = "",
    this.meal = "anytime",
    this.frequency = "",
    String? id, // Allow optional id
    List<dynamic>? schedules,
  })  : id = id ?? generateRandomString(), // Generate only if not provided
        schedules = schedules ?? [];

  factory MedicineInfo.fromJson(Map<String, dynamic> json) {
    return MedicineInfo(
      id: json['id'], // Use id from JSON if available
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? '',
      duration: json['duration'] ?? '',
      meal: json['meal'] ?? 'anytime',
      frequency: json['frequency'] ?? '',
      schedules: json['schedules'],
    );
  }
}
