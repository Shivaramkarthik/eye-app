import 'package:flutter/material.dart';
import '../utils/app_icons.dart';



class EyeHealthScoreCard extends StatelessWidget {
  final int score;
  final String explanation;

  const EyeHealthScoreCard({
    Key? key,
    required this.score,
    required this.explanation,
  }) : super(key: key);

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF10B981); // Emerald Green
    if (score >= 50) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }

  @override
  Widget build(BuildContext context) {
    Color scoreColor = _getScoreColor(score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.activity, color: scoreColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Eye Health Score",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    Text(
                      "$score / 100",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  score >= 80 ? "Optimal" : score >= 50 ? "Moderate" : "Action Needed",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(LucideIcons.info, size: 14, color: Color(0xFF64748B)),
              SizedBox(width: 6),
              Text(
                "WHY THIS SCORE WAS GENERATED:",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            explanation,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
