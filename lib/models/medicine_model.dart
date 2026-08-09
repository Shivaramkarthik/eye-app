import 'dart:convert';

class MedicineModel {
  final String id;
  final String profileId;
  final String userId;
  final String name;
  final String type; // 'Drop', 'Tablet', 'Ointment', 'Custom'
  final String dosage; // e.g., '1 drop twice daily'
  final String startDate;
  final String? endDate;
  final List<String> times; // ['08:00 AM', '08:00 PM']
  final String tone; // 'Soft Chime', 'Gentle Bell', 'Alert Beep'
  final bool vibrationEnabled;
  final bool active;
  final List<String> completedLogs; // ['2026-08-09_08:00 AM']
  final String createdAt;

  MedicineModel({
    required this.id,
    required this.profileId,
    required this.userId,
    required this.name,
    required this.type,
    required this.dosage,
    required this.startDate,
    this.endDate,
    required this.times,
    this.tone = 'Soft Chime',
    this.vibrationEnabled = true,
    this.active = true,
    this.completedLogs = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileId': profileId,
      'userId': userId,
      'name': name,
      'type': type,
      'dosage': dosage,
      'startDate': startDate,
      'endDate': endDate,
      'times': jsonEncode(times),
      'tone': tone,
      'vibrationEnabled': vibrationEnabled ? 1 : 0,
      'active': active ? 1 : 0,
      'completedLogs': jsonEncode(completedLogs),
      'createdAt': createdAt,
    };
  }

  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedTimes = [];
    if (map['times'] != null) {
      try {
        if (map['times'] is String) {
          parsedTimes = List<String>.from(jsonDecode(map['times']));
        } else if (map['times'] is List) {
          parsedTimes = List<String>.from(map['times']);
        }
      } catch (_) {}
    }

    List<String> parsedLogs = [];
    if (map['completedLogs'] != null) {
      try {
        if (map['completedLogs'] is String) {
          parsedLogs = List<String>.from(jsonDecode(map['completedLogs']));
        } else if (map['completedLogs'] is List) {
          parsedLogs = List<String>.from(map['completedLogs']);
        }
      } catch (_) {}
    }

    return MedicineModel(
      id: map['id'] ?? '',
      profileId: map['profileId'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'Drop',
      dosage: map['dosage'] ?? '',
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'],
      times: parsedTimes,
      tone: map['tone'] ?? 'Soft Chime',
      vibrationEnabled: (map['vibrationEnabled'] == 1 || map['vibrationEnabled'] == true),
      active: (map['active'] == 1 || map['active'] == true),
      completedLogs: parsedLogs,
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
