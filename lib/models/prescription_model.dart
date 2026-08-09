class PrescriptionModel {
  final String id;
  final String profileId;
  final String userId;
  final String prescriptionDate;
  final String doctorName;
  final String clinicName;
  final double? rightSph; // SPH OD
  final double? rightCyl; // CYL OD
  final int? rightAxis;   // AXIS OD
  final double? leftSph;  // SPH OS
  final double? leftCyl;  // CYL OS
  final int? leftAxis;    // AXIS OS
  final double? addPower;
  final double? pd;       // Pupillary Distance
  final String? notes;
  final String? imageUrl;
  final bool isCurrent;
  final String createdAt;

  PrescriptionModel({
    required this.id,
    required this.profileId,
    required this.userId,
    required this.prescriptionDate,
    this.doctorName = '',
    this.clinicName = '',
    this.rightSph,
    this.rightCyl,
    this.rightAxis,
    this.leftSph,
    this.leftCyl,
    this.leftAxis,
    this.addPower,
    this.pd,
    this.notes,
    this.imageUrl,
    this.isCurrent = true,
    required this.createdAt,
  });

  bool get isMissingSphOrCyl =>
      rightSph == null || rightCyl == null || leftSph == null || leftCyl == null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileId': profileId,
      'userId': userId,
      'prescriptionDate': prescriptionDate,
      'doctorName': doctorName,
      'clinicName': clinicName,
      'rightSph': rightSph,
      'rightCyl': rightCyl,
      'rightAxis': rightAxis,
      'leftSph': leftSph,
      'leftCyl': leftCyl,
      'leftAxis': leftAxis,
      'addPower': addPower,
      'pd': pd,
      'notes': notes,
      'imageUrl': imageUrl,
      'isCurrent': isCurrent ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory PrescriptionModel.fromMap(Map<String, dynamic> map) {
    return PrescriptionModel(
      id: map['id'] ?? '',
      profileId: map['profileId'] ?? '',
      userId: map['userId'] ?? '',
      prescriptionDate: map['prescriptionDate'] ?? '',
      doctorName: map['doctorName'] ?? '',
      clinicName: map['clinicName'] ?? '',
      rightSph: (map['rightSph'] as num?)?.toDouble(),
      rightCyl: (map['rightCyl'] as num?)?.toDouble(),
      rightAxis: (map['rightAxis'] as num?)?.toInt(),
      leftSph: (map['leftSph'] as num?)?.toDouble(),
      leftCyl: (map['leftCyl'] as num?)?.toDouble(),
      leftAxis: (map['leftAxis'] as num?)?.toInt(),
      addPower: (map['addPower'] as num?)?.toDouble(),
      pd: (map['pd'] as num?)?.toDouble(),
      notes: map['notes'],
      imageUrl: map['imageUrl'],
      isCurrent: (map['isCurrent'] == 1 || map['isCurrent'] == true),
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
