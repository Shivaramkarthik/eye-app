import 'package:flutter/material.dart';
import '../utils/app_icons.dart';



class MissingSphWarningBanner extends StatelessWidget {
  const MissingSphWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.alertTriangle, size: 20, color: Color(0xFFDC2626)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "Warning: Missing Prescription Numbers",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF991B1B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Sphere (SPH) or Cylinder (CYL) values are required for accurate eye history tracking. Please fill in all fields.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB91C1C),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
