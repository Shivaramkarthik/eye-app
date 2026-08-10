class EyeCareScoreModel {
  final String id;
  final String profileId;
  final int score;
  final int prescriptionCompletenessScore; // max 20
  final int prescriptionStabilityScore;    // max 15
  final int medicationAdherenceScore;      // max 20
  final int followupRecencyScore;          // max 10
  final int recordCompletenessScore;       // max 10
  final int careRoutineConsistencyScore;   // max 10
  final int historyQualityScore;           // max 15
  final String explanation;
  final List<String> reasons;
  final int algorithmVersion;
  final String calculatedAt;

  EyeCareScoreModel({
    required this.id,
    required this.profileId,
    required this.score,
    required this.prescriptionCompletenessScore,
    required this.prescriptionStabilityScore,
    required this.medicationAdherenceScore,
    required this.followupRecencyScore,
    required this.recordCompletenessScore,
    required this.careRoutineConsistencyScore,
    required this.historyQualityScore,
    required this.explanation,
    required this.reasons,
    this.algorithmVersion = 2,
    required this.calculatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'score': score,
      'prescription_completeness_score': prescriptionCompletenessScore,
      'prescription_stability_score': prescriptionStabilityScore,
      'medication_adherence_score': medicationAdherenceScore,
      'followup_recency_score': followupRecencyScore,
      'record_completeness_score': recordCompletenessScore,
      'care_routine_consistency_score': careRoutineConsistencyScore,
      'history_quality_score': historyQualityScore,
      'explanation': explanation,
      'algorithm_version': algorithmVersion,
      'calculated_at': calculatedAt,
    };
  }

  factory EyeCareScoreModel.fromMap(Map<String, dynamic> map, {List<String> reasons = const []}) {
    return EyeCareScoreModel(
      id: map['id'] ?? '',
      profileId: map['profile_id'] ?? map['profileId'] ?? '',
      score: (map['score'] as num?)?.toInt() ?? 50,
      prescriptionCompletenessScore: (map['prescription_completeness_score'] as num?)?.toInt() ?? 10,
      prescriptionStabilityScore: (map['prescription_stability_score'] as num?)?.toInt() ?? 10,
      medicationAdherenceScore: (map['medication_adherence_score'] as num?)?.toInt() ?? 10,
      followupRecencyScore: (map['followup_recency_score'] as num?)?.toInt() ?? 5,
      recordCompletenessScore: (map['record_completeness_score'] as num?)?.toInt() ?? 5,
      careRoutineConsistencyScore: (map['care_routine_consistency_score'] as num?)?.toInt() ?? 5,
      historyQualityScore: (map['history_quality_score'] as num?)?.toInt() ?? 5,
      explanation: map['explanation'] ?? '',
      reasons: reasons,
      algorithmVersion: (map['algorithm_version'] as num?)?.toInt() ?? 2,
      calculatedAt: map['calculated_at'] ?? map['calculatedAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
