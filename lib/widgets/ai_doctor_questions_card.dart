import 'package:flutter/material.dart';
import '../utils/app_icons.dart';



class AiDoctorQuestionsCard extends StatelessWidget {
  final List<String> questions;

  const AiDoctorQuestionsCard({Key? key, required this.questions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Row(
            children: [
              Icon(LucideIcons.sparkles, size: 18, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text(
                "AI Suggested Doctor Questions",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...questions.map((q) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                    Expanded(
                      child: Text(
                        q,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.3),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
