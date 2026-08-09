import 'dart:convert';

class ProfileModel {
  final String id;
  final String userId;
  final String name;
  final String dob;
  final String gender;
  final String type; // 'Adult' | 'Child'
  final String relationship; // 'Self', 'Child', 'Spouse', 'Parent', 'Other'
  final String? prescriptionType; // 'Myopia', 'Hypermetropia', 'Astigmatism', 'Presbyopia', etc.
  final List<String> symptoms; // ['Blurred vision', 'Headache', 'Eye strain', etc.]
  final String? blurredVisionType; // 'Near', 'Distance', 'Both', 'Not sure'
  final bool isArchived;
  final String createdAt;

  ProfileModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.dob,
    required this.gender,
    required this.type,
    required this.relationship,
    this.prescriptionType,
    this.symptoms = const [],
    this.blurredVisionType,
    this.isArchived = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'dob': dob,
      'gender': gender,
      'type': type,
      'relationship': relationship,
      'prescriptionType': prescriptionType,
      'symptoms': jsonEncode(symptoms),
      'blurredVisionType': blurredVisionType,
      'isArchived': isArchived ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedSymptoms = [];
    if (map['symptoms'] != null) {
      try {
        if (map['symptoms'] is String) {
          parsedSymptoms = List<String>.from(jsonDecode(map['symptoms']));
        } else if (map['symptoms'] is List) {
          parsedSymptoms = List<String>.from(map['symptoms']);
        }
      } catch (_) {}
    }

    return ProfileModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      dob: map['dob'] ?? '',
      gender: map['gender'] ?? 'Other',
      type: map['type'] ?? 'Adult',
      relationship: map['relationship'] ?? 'Self',
      prescriptionType: map['prescriptionType'],
      symptoms: parsedSymptoms,
      blurredVisionType: map['blurredVisionType'],
      isArchived: (map['isArchived'] == 1 || map['isArchived'] == true),
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
