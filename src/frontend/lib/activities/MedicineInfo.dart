import 'package:medico_/functions/function.dart';

class MedicineInfo {
  final String id;
  final String name;
  final String quantity;
  final String duration; //in days only
  final String meal;
  final String frequency;
  List<dynamic>? schedules;

  MedicineInfo({
    required this.name,
    this.quantity = "",
    this.duration = "",
    this.meal = "anytime",
    this.frequency = "",
    id = "x0",
    schedules,
  })  : schedules = schedules ?? [],
        id = generateRandomString();

  factory MedicineInfo.fromJson(Map<String, dynamic> json) {
    return MedicineInfo(
      id: json['id'] ?? generateRandomString(),
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? '',
      duration: json['duration'] ?? '',
      meal: json['meal'] ?? 'anytime',
      frequency: json['frequency'] ?? '',
      schedules: json['schedules'],
    );
  }
}
