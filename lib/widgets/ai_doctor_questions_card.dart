import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AiDoctorQuestionsCard extends StatelessWidget {
  final List<String> questions;

  const AiDoctorQuestionsCard({Key? key, required this.questions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.purpleGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                "AI Doctor Questions",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            // Alternate alignment to simulate chat
            bool isAi = index % 2 == 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Align(
                alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isAi ? null : AppTheme.primaryGradient,
                    color: isAi ? AppTheme.surface : null,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isAi ? 4 : 16),
                      bottomRight: Radius.circular(isAi ? 16 : 4),
                    ),
                  ),
                  child: Text(
                    question,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isAi ? AppTheme.textPrimary : Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
