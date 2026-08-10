class AiSummaryModel {
  final String id;
  final String profileId;
  final String summaryText;
  final String language;
  final String modelVersion;
  final String promptVersion;
  final String generatedAt;

  AiSummaryModel({
    required this.id,
    required this.profileId,
    required this.summaryText,
    this.language = 'en',
    this.modelVersion = 'gemini-1.5-flash',
    this.promptVersion = 'v2.0',
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'summary_text': summaryText,
      'language': language,
      'model_version': modelVersion,
      'prompt_version': promptVersion,
      'generated_at': generatedAt,
    };
  }

  factory AiSummaryModel.fromMap(Map<String, dynamic> map) {
    return AiSummaryModel(
      id: map['id'] ?? '',
      profileId: map['profile_id'] ?? map['profileId'] ?? '',
      summaryText: map['summary_text'] ?? map['summaryText'] ?? '',
      language: map['language'] ?? 'en',
      modelVersion: map['model_version'] ?? map['modelVersion'] ?? 'gemini-1.5-flash',
      promptVersion: map['prompt_version'] ?? map['promptVersion'] ?? 'v2.0',
      generatedAt: map['generated_at'] ?? map['generatedAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}

class DoctorQuestionModel {
  final String id;
  final String profileId;
  final String questionText;
  final String category;
  final String generatedAt;

  DoctorQuestionModel({
    required this.id,
    required this.profileId,
    required this.questionText,
    this.category = 'General',
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'question_text': questionText,
      'category': category,
      'generated_at': generatedAt,
    };
  }

  factory DoctorQuestionModel.fromMap(Map<String, dynamic> map) {
    return DoctorQuestionModel(
      id: map['id'] ?? '',
      profileId: map['profile_id'] ?? map['profileId'] ?? '',
      questionText: map['question_text'] ?? map['questionText'] ?? '',
      category: map['category'] ?? 'General',
      generatedAt: map['generated_at'] ?? map['generatedAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
