class MedicationLogModel {
  final String id;
  final String medicationId;
  final String scheduleId;
  final String scheduledAt; // ISO or date string '2026-08-10_08:00 AM'
  final String? actualAt;
  final String status; // 'TAKEN', 'SNOOZED', 'SKIPPED', 'MISSED'
  final String createdAt;

  MedicationLogModel({
    required this.id,
    required this.medicationId,
    required this.scheduleId,
    required this.scheduledAt,
    this.actualAt,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'schedule_id': scheduleId,
      'scheduled_at': scheduledAt,
      'actual_at': actualAt,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory MedicationLogModel.fromMap(Map<String, dynamic> map) {
    return MedicationLogModel(
      id: map['id'] ?? '',
      medicationId: map['medication_id'] ?? map['medicationId'] ?? '',
      scheduleId: map['schedule_id'] ?? map['scheduleId'] ?? '',
      scheduledAt: map['scheduled_at'] ?? map['scheduledAt'] ?? '',
      actualAt: map['actual_at'] ?? map['actualAt'],
      status: map['status'] ?? 'TAKEN',
      createdAt: map['created_at'] ?? map['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
