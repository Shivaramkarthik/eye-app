import 'package:flutter/material.dart';
import '../models/prescription_model.dart';

class AcademicBwChart extends StatelessWidget {
  final List<PrescriptionModel> prescriptions;

  const AcademicBwChart({Key? key, required this.prescriptions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // Plain white background
        border: Border.all(color: Colors.black54, width: 1.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "FIGURE 1: REFRACTION POWER TREND (SPHERICAL EQUIVALENT)",
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 0.8),
                ),
                child: const Text(
                  "ACADEMIC B&W GRID",
                  style: TextStyle(fontFamily: 'Courier', fontSize: 9, color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              painter: AcademicGridPainter(prescriptions: prescriptions),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("──■── Right Eye (OD)", style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black)),
              SizedBox(width: 20),
              Text("┅┅▲┅┅ Left Eye (OS)", style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black)),
            ],
          ),
        ],
      ),
    );
  }
}

/// CustomPainter that renders strict black and white academic technical chart on engineering grid
class AcademicGridPainter extends CustomPainter {
  final List<PrescriptionModel> prescriptions;

  AcademicGridPainter({required this.prescriptions});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw subtle light grey engineering grid
    final gridPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 0.8;

    const gridSpacing = 16.0;

    for (double x = 0; x <= size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw axes (Strict Black)
    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5;

    canvas.drawLine(Offset(35, 0), Offset(35, size.height - 20), axisPaint); // Y axis
    canvas.drawLine(Offset(35, size.height - 20), Offset(size.width, size.height - 20), axisPaint); // X axis

    // Draw Y axis labels (SPH Diopters)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    List<double> yTicks = [0.0, -1.0, -2.0, -3.0, -4.0];
    for (int i = 0; i < yTicks.length; i++) {
      double yPos = (size.height - 25) * (i / (yTicks.length - 1));
      textPainter.text = TextSpan(
        text: "${yTicks[i].toStringAsFixed(1)}D",
        style: const TextStyle(fontFamily: 'Courier', fontSize: 9, color: Colors.black),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, yPos - 4));
    }

    // Plot Points if prescriptions exist
    if (prescriptions.isEmpty) {
      textPainter.text = const TextSpan(
        text: "[No historical prescriptions to plot]",
        style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width * 0.3, size.height * 0.4));
      return;
    }

    // Draw Right Eye (OD) solid line & Left Eye (OS) dashed line
    final rightLinePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    double plotWidth = size.width - 50;
    double stepX = prescriptions.length > 1 ? plotWidth / (prescriptions.length - 1) : plotWidth;

    Path rightPath = Path();
    Path leftPath = Path();

    for (int i = 0; i < prescriptions.length; i++) {
      final p = prescriptions[i];
      double x = 40 + (i * stepX);

      double rSph = p.rightSph ?? -2.0;
      double lSph = p.leftSph ?? -2.0;

      // Map SPH values 0 to -4 to Y coordinates
      double rY = (size.height - 25) * (rSph.abs() / 4.0).clamp(0.0, 1.0);
      double lY = (size.height - 25) * (lSph.abs() / 4.0).clamp(0.0, 1.0);

      if (i == 0) {
        rightPath.moveTo(x, rY);
        leftPath.moveTo(x, lY);
      } else {
        rightPath.lineTo(x, rY);
        leftPath.lineTo(x, lY);
      }

      // Draw OD square point
      canvas.drawRect(Rect.fromCenter(center: Offset(x, rY), width: 6, height: 6), pointPaint);

      // Draw OS triangle point
      Path tri = Path()
        ..moveTo(x, lY - 4)
        ..lineTo(x - 4, lY + 3)
        ..lineTo(x + 4, lY + 3)
        ..close();
      canvas.drawPath(tri, pointPaint);
    }

    canvas.drawPath(rightPath, rightLinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
