class MedicationScheduleModel {
  final String id;
  final String medicationId;
  final String time; // '08:00 AM'
  final String tone;
  final bool vibrationEnabled;
  final bool enabled;
  final String createdAt;
  final String updatedAt;

  MedicationScheduleModel({
    required this.id,
    required this.medicationId,
    required this.time,
    this.tone = 'Soft Chime',
    this.vibrationEnabled = true,
    this.enabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'time': time,
      'tone': tone,
      'vibration_enabled': vibrationEnabled ? 1 : 0,
      'enabled': enabled ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory MedicationScheduleModel.fromMap(Map<String, dynamic> map) {
    return MedicationScheduleModel(
      id: map['id'] ?? '',
      medicationId: map['medication_id'] ?? map['medicationId'] ?? '',
      time: map['time'] ?? '08:00 AM',
      tone: map['tone'] ?? 'Soft Chime',
      vibrationEnabled: (map['vibration_enabled'] == 1 || map['vibration_enabled'] == true || map['vibrationEnabled'] == 1 || map['vibrationEnabled'] == true),
      enabled: (map['enabled'] == 1 || map['enabled'] == true),
      createdAt: map['created_at'] ?? map['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at'] ?? map['updatedAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
