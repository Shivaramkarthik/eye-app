import 'package:flutter/material.dart';
import '../models/prescription_model.dart';
import '../utils/app_theme.dart';

class AcademicBwChart extends StatelessWidget {
  final List<PrescriptionModel> prescriptions;

  const AcademicBwChart({super.key, required this.prescriptions});

  @override
  Widget build(BuildContext context) {
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
                      color: AppTheme.textPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.ssid_chart_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Refraction Trend",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "SPH Trend",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              painter: _ModernGridPainter(prescriptions: prescriptions),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppTheme.primary, "Right Eye (OD)"),
              const SizedBox(width: 24),
              _legendDot(AppTheme.accent, "Left Eye (OS)"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ModernGridPainter extends CustomPainter {
  final List<PrescriptionModel> prescriptions;

  _ModernGridPainter({required this.prescriptions});

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFF0F4F8)
      ..strokeWidth = 1;

    const gridSpacing = 20.0;
    for (double y = 0; y <= size.height; y += gridSpacing) {
      canvas.drawLine(Offset(35, y), Offset(size.width, y), gridPaint);
    }

    // Y axis
    final axisPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(35, 0), Offset(35, size.height - 20), axisPaint);

    // Y axis labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    List<double> yTicks = [0.0, -1.0, -2.0, -3.0, -4.0];
    for (int i = 0; i < yTicks.length; i++) {
      double yPos = (size.height - 25) * (i / (yTicks.length - 1));
      textPainter.text = TextSpan(
        text: "${yTicks[i].toStringAsFixed(1)}D",
        style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, yPos - 4));
    }

    if (prescriptions.isEmpty) {
      textPainter.text = const TextSpan(
        text: "No prescriptions to plot",
        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width * 0.3, size.height * 0.4));
      return;
    }

    double plotWidth = size.width - 50;
    double stepX = prescriptions.length > 1 ? plotWidth / (prescriptions.length - 1) : plotWidth;

    // Right eye path (teal)
    final rightLinePaint = Paint()
      ..color = const Color(0xFF0A6B7C)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Left eye path (amber)
    final leftLinePaint = Paint()
      ..color = const Color(0xFFFFB74D)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Path rightPath = Path();
    Path leftPath = Path();
    List<Offset> rightPoints = [];
    List<Offset> leftPoints = [];

    for (int i = 0; i < prescriptions.length; i++) {
      final p = prescriptions[i];
      double x = 40 + (i * stepX);
      double rSph = p.rightSph ?? -2.0;
      double lSph = p.leftSph ?? -2.0;
      double rY = (size.height - 25) * (rSph.abs() / 4.0).clamp(0.0, 1.0);
      double lY = (size.height - 25) * (lSph.abs() / 4.0).clamp(0.0, 1.0);

      rightPoints.add(Offset(x, rY));
      leftPoints.add(Offset(x, lY));

      if (i == 0) {
        rightPath.moveTo(x, rY);
        leftPath.moveTo(x, lY);
      } else {
        rightPath.lineTo(x, rY);
        leftPath.lineTo(x, lY);
      }
    }

    canvas.drawPath(rightPath, rightLinePaint);
    canvas.drawPath(leftPath, leftLinePaint);

    // Draw points with glow
    for (final pt in rightPoints) {
      canvas.drawCircle(pt, 5, Paint()..color = const Color(0xFF0A6B7C).withValues(alpha: 0.15));
      canvas.drawCircle(pt, 4, Paint()..color = Colors.white);
      canvas.drawCircle(pt, 3, Paint()..color = const Color(0xFF0A6B7C));
    }
    for (final pt in leftPoints) {
      canvas.drawCircle(pt, 5, Paint()..color = const Color(0xFFFFB74D).withValues(alpha: 0.15));
      canvas.drawCircle(pt, 4, Paint()..color = Colors.white);
      canvas.drawCircle(pt, 3, Paint()..color = const Color(0xFFFFB74D));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
