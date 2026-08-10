class PrescriptionEyeValueModel {
  final String id;
  final String prescriptionId;
  final String eye; // 'OD' (Right) or 'OS' (Left)
  final double? sph;
  final double? cyl;
  final int? axis;
  final String sphStatus; // 'CONFIRMED', 'MANUAL', 'OCR_EXTRACTED', 'UNCERTAIN', 'MISSING'
  final String cylStatus;
  final String axisStatus;
  final String createdAt;

  PrescriptionEyeValueModel({
    required this.id,
    required this.prescriptionId,
    required this.eye,
    this.sph,
    this.cyl,
    this.axis,
    this.sphStatus = 'CONFIRMED',
    this.cylStatus = 'CONFIRMED',
    this.axisStatus = 'CONFIRMED',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prescription_id': prescriptionId,
      'eye': eye,
      'sph': sph,
      'cyl': cyl,
      'axis': axis,
      'sph_status': sphStatus,
      'cyl_status': cylStatus,
      'axis_status': axisStatus,
      'created_at': createdAt,
    };
  }

  factory PrescriptionEyeValueModel.fromMap(Map<String, dynamic> map) {
    return PrescriptionEyeValueModel(
      id: map['id'] ?? '',
      prescriptionId: map['prescription_id'] ?? map['prescriptionId'] ?? '',
      eye: map['eye'] ?? 'OD',
      sph: (map['sph'] as num?)?.toDouble(),
      cyl: (map['cyl'] as num?)?.toDouble(),
      axis: (map['axis'] as num?)?.toInt(),
      sphStatus: map['sph_status'] ?? map['sphStatus'] ?? 'CONFIRMED',
      cylStatus: map['cyl_status'] ?? map['cylStatus'] ?? 'CONFIRMED',
      axisStatus: map['axis_status'] ?? map['axisStatus'] ?? 'CONFIRMED',
      createdAt: map['created_at'] ?? map['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
