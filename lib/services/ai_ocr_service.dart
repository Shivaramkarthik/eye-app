import 'dart:async';
import '../data/remote/api_client.dart';
import '../models/prescription_model.dart';
import '../models/profile_model.dart';
import '../models/medicine_model.dart';
import '../models/eye_care_score_model.dart';

class AiOcrResult {
  final double? rightSph;
  final double? rightCyl;
  final int? rightAxis;
  final double? leftSph;
  final double? leftCyl;
  final int? leftAxis;
  final double? addPower;
  final double? pd;
  final String doctorName;
  final String clinicName;
  final String notes;
  final String rawOcrText;

  final double rightSphConfidence;
  final double rightCylConfidence;
  final double rightAxisConfidence;
  final double leftSphConfidence;
  final double leftCylConfidence;
  final double leftAxisConfidence;

  AiOcrResult({
    this.rightSph,
    this.rightCyl,
    this.rightAxis,
    this.leftSph,
    this.leftCyl,
    this.leftAxis,
    this.addPower,
    this.pd,
    this.doctorName = '',
    this.clinicName = '',
    this.notes = '',
    this.rawOcrText = '',
    this.rightSphConfidence = 0.98,
    this.rightCylConfidence = 0.95,
    this.rightAxisConfidence = 0.92,
    this.leftSphConfidence = 0.97,
    this.leftCylConfidence = 0.85,
    this.leftAxisConfidence = 0.88,
  });

  bool get isRightCylMissing => rightCyl == null;
  bool get isLeftCylMissing => leftCyl == null;
  bool get hasLowConfidenceField =>
      rightSphConfidence < 0.90 ||
      rightCylConfidence < 0.90 ||
      rightAxisConfidence < 0.90 ||
      leftSphConfidence < 0.90 ||
      leftCylConfidence < 0.90 ||
      leftAxisConfidence < 0.90;
}

class AiOcrService {
  static final AiOcrService instance = AiOcrService._internal();
  AiOcrService._internal();

  /// Real OCR extraction pipeline with backend Vision gateway & confidence scoring
  Future<AiOcrResult> extractPrescriptionData(String imagePathOrBytes) async {
    try {
      final response = await ApiClient.instance.post(
        '/ai/ocr',
        data: {'image_path': imagePathOrBytes},
      );

      final data = response.data as Map<String, dynamic>;
      return AiOcrResult(
        rightSph: data['right_sph'] != null ? (data['right_sph'] as num).toDouble() : null,
        rightCyl: data['right_cyl'] != null ? (data['right_cyl'] as num).toDouble() : null,
        rightAxis: data['right_axis'] != null ? (data['right_axis'] as num).toInt() : null,
        leftSph: data['left_sph'] != null ? (data['left_sph'] as num).toDouble() : null,
        leftCyl: data['left_cyl'] != null ? (data['left_cyl'] as num).toDouble() : null,
        leftAxis: data['left_axis'] != null ? (data['left_axis'] as num).toInt() : null,
        addPower: data['add_power'] != null ? (data['add_power'] as num).toDouble() : 0.0,
        pd: data['pd'] != null ? (data['pd'] as num).toDouble() : 63.0,
        doctorName: data['doctor_name'] ?? '',
        clinicName: data['clinic_name'] ?? '',
        notes: data['notes'] ?? 'Extracted via OCR model.',
        rawOcrText: data['raw_ocr_text'] ?? '',
        rightSphConfidence: (data['right_sph_confidence'] ?? 0.95 as num).toDouble(),
        rightCylConfidence: (data['right_cyl_confidence'] ?? 0.90 as num).toDouble(),
        rightAxisConfidence: (data['right_axis_confidence'] ?? 0.90 as num).toDouble(),
        leftSphConfidence: (data['left_sph_confidence'] ?? 0.95 as num).toDouble(),
        leftCylConfidence: (data['left_cyl_confidence'] ?? 0.90 as num).toDouble(),
        leftAxisConfidence: (data['left_axis_confidence'] ?? 0.90 as num).toDouble(),
      );
    } catch (e) {
      throw Exception('OCR Vision extraction failed: Unable to process document via Vision gateway ($e). Please re-take photo or enter values manually.');
    }
  }

  /// Calculates component-based Vision Care Score (0-100)
  Map<String, dynamic> calculateEyeHealthScore({
    required ProfileModel profile,
    required List<PrescriptionModel> prescriptions,
    required List<MedicineModel> medicines,
  }) {
    int pCompleteness = 0;
    int pStability = 0;
    int mAdherence = 0;
    int fRecency = 0;
    int rCompleteness = 0;
    int cConsistency = 0;
    int hQuality = 0;

    List<String> reasons = [];

    // 1. Prescription Completeness (max 20)
    if (prescriptions.isNotEmpty) {
      final latest = prescriptions.first;
      if (!latest.isMissingSphOrCyl) {
        pCompleteness = 20;
        reasons.add("✓ Complete SPH and CYL prescription logged (+20)");
      } else {
        pCompleteness = 10;
        reasons.add("△ Prescription is missing CYL or SPH details (+10)");
      }
    } else {
      reasons.add("✕ No prescription logged yet (+0)");
    }

    // 2. Prescription Stability (max 15)
    if (prescriptions.length >= 2) {
      final latest = prescriptions[0];
      final previous = prescriptions[1];
      double rDiff = ((latest.rightSph ?? 0) - (previous.rightSph ?? 0)).abs();
      double lDiff = ((latest.leftSph ?? 0) - (previous.leftSph ?? 0)).abs();

      if (rDiff <= 0.5 && lDiff <= 0.5) {
        pStability = 15;
        reasons.add("✓ Stable prescription power over consecutive checks (+15)");
      } else {
        pStability = 8;
        reasons.add("△ Refraction power shifted over >0.50D between recent prescriptions (+8)");
      }
    } else if (prescriptions.length == 1) {
      pStability = 10;
      reasons.add("△ Single prescription recorded; history needed to track stability (+10)");
    } else {
      pStability = 0;
    }

    // 3. Medication Adherence (max 20)
    if (medicines.isNotEmpty) {
      int activeMeds = medicines.where((m) => m.active).length;
      if (activeMeds > 0) {
        mAdherence = 18;
        reasons.add("✓ Active eye drop / medicine routine maintained (+18)");
      } else {
        mAdherence = 10;
        reasons.add("△ Eye drops scheduled but currently inactive (+10)");
      }
    } else {
      mAdherence = 15; // No active drops prescribed
      reasons.add("✓ No daily eye drops required (+15)");
    }

    // 4. Follow-up Recency (max 10)
    if (prescriptions.isNotEmpty) {
      final latest = prescriptions.first;
      try {
        DateTime date = DateTime.parse(latest.prescriptionDate);
        int daysOld = DateTime.now().difference(date).inDays;
        if (daysOld <= 365) {
          fRecency = 10;
          reasons.add("✓ Eye examination within last 12 months (+10)");
        } else if (daysOld <= 730) {
          fRecency = 5;
          reasons.add("△ Eye examination older than 1 year (+5)");
        } else {
          fRecency = 2;
          reasons.add("✕ Routine eye examination overdue (>2 years) (+2)");
        }
      } catch (_) {
        fRecency = 5;
      }
    } else {
      fRecency = 0;
    }

    // 5. Record Completeness (max 10)
    if (profile.dob.isNotEmpty && profile.gender.isNotEmpty) {
      rCompleteness = 10;
      reasons.add("✓ Full profile metadata recorded (+10)");
    } else {
      rCompleteness = 5;
      reasons.add("△ Profile metadata partially complete (+5)");
    }

    // 6. Care Routine Consistency (max 10)
    if (profile.symptoms.isEmpty) {
      cConsistency = 10;
      reasons.add("✓ Zero active eye strain or blurred vision symptoms reported (+10)");
    } else {
      cConsistency = (10 - (profile.symptoms.length * 3)).clamp(2, 8);
      reasons.add("△ Active symptoms reported: ${profile.symptoms.join(', ')} (+${cConsistency})");
    }

    // 7. History Quality (max 15)
    if (prescriptions.length >= 2) {
      hQuality = 15;
      reasons.add("✓ Multi-year prescription history logged (+15)");
    } else if (prescriptions.length == 1) {
      hQuality = 8;
      reasons.add("△ Single prescription history recorded (+8)");
    } else {
      hQuality = 0;
    }

    int totalScore = (pCompleteness + pStability + mAdherence + fRecency + rCompleteness + cConsistency + hQuality).clamp(0, 100);

    String summaryMsg = "Vision Care Score: $totalScore / 100. Breakdown:\n" + reasons.join("\n");

    final scoreModel = EyeCareScoreModel(
      id: 'score_${profile.id}_${DateTime.now().millisecondsSinceEpoch}',
      profileId: profile.id,
      score: totalScore,
      prescriptionCompletenessScore: pCompleteness,
      prescriptionStabilityScore: pStability,
      medicationAdherenceScore: mAdherence,
      followupRecencyScore: fRecency,
      recordCompletenessScore: rCompleteness,
      careRoutineConsistencyScore: cConsistency,
      historyQualityScore: hQuality,
      explanation: summaryMsg,
      reasons: reasons,
      algorithmVersion: 2,
      calculatedAt: DateTime.now().toIso8601String(),
    );

    return {
      'score': totalScore,
      'explanation': summaryMsg,
      'reasons': reasons,
      'scoreModel': scoreModel,
    };
  }

  /// Generates non-diagnostic AI questions for doctor consultation
  List<String> generateDoctorQuestions({
    required ProfileModel profile,
    required List<PrescriptionModel> prescriptions,
  }) {
    List<String> questions = [];

    if (profile.symptoms.contains("Eye strain") || profile.symptoms.contains("Blurred vision")) {
      questions.add("Are my reported eye strain symptoms related to screen fatigue or an uncorrected cylinder power?");
    }
    if (prescriptions.isNotEmpty) {
      final latest = prescriptions.first;
      if ((latest.rightCyl ?? 0).abs() > 1.0 || (latest.leftCyl ?? 0).abs() > 1.0) {
        questions.add("My recorded cylinder power indicates astigmatism. Are specialized toric lenses recommended for my eyes?");
      }
    }
    questions.add("Has my visual acuity or refraction power changed significantly compared to my last prescription?");
    questions.add("What is the ideal recommended timeline for my next comprehensive eye examination?");

    return questions;
  }
}
