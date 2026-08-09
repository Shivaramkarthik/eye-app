import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AiDoctorQuestionsCard extends StatelessWidget {
  final List<String> questions;
  final Function(String question)? onQuestionTap;

  const AiDoctorQuestionsCard({
    Key? key,
    required this.questions,
    this.onQuestionTap,
  }) : super(key: key);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
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
              if (onQuestionTap != null)
                TextButton.icon(
                  onPressed: () => onQuestionTap?.call(questions.first),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppTheme.primary),
                  label: const Text("Chat AI", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Tap any question to ask your Specz AI Assistant:",
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            bool isAi = index % 2 == 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Align(
                alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                child: InkWell(
                  onTap: () => onQuestionTap?.call(question),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
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
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: isAi ? AppTheme.textHint : Colors.white70,
                        ),
                      ],
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
