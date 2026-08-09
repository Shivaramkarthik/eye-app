import 'package:flutter/material.dart';
import '../utils/app_icons.dart';



class MedicalDisclaimerBanner extends StatelessWidget {
  final String text;
  const MedicalDisclaimerBanner({Key? key, this.text = ''}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Icon(LucideIcons.shieldAlert, size: 18, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text.isNotEmpty
                  ? text
                  : "Specz.co helps organize personal eye-care records and reminders. It does not provide a medical diagnosis and does not replace an eye-care professional.",
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF92400E),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
