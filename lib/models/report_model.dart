class ReportModel {
  final String id;
  final String profileId;
  final String userId;
  final String reportDate;
  final String title;
  final String clinicName;
  final String? filePath;
  final String? notes;
  final String? followUpDate;
  final String createdAt;

  ReportModel({
    required this.id,
    required this.profileId,
    required this.userId,
    required this.reportDate,
    required this.title,
    this.clinicName = '',
    this.filePath,
    this.notes,
    this.followUpDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileId': profileId,
      'userId': userId,
      'reportDate': reportDate,
      'title': title,
      'clinicName': clinicName,
      'filePath': filePath,
      'notes': notes,
      'followUpDate': followUpDate,
      'createdAt': createdAt,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] ?? '',
      profileId: map['profileId'] ?? '',
      userId: map['userId'] ?? '',
      reportDate: map['reportDate'] ?? '',
      title: map['title'] ?? '',
      clinicName: map['clinicName'] ?? '',
      filePath: map['filePath'],
      notes: map['notes'],
      followUpDate: map['followUpDate'],
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
