import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/profile_model.dart';
import '../models/prescription_model.dart';
import '../models/report_model.dart';
import '../models/medicine_model.dart';

class PdfService {
  static final PdfService instance = PdfService._internal();
  PdfService._internal();

  Future<Uint8List> generateProfileSummaryPdf({
    required ProfileModel profile,
    required List<PrescriptionModel> prescriptions,
    required List<ReportModel> reports,
    required List<MedicineModel> medicines,
    required int eyeHealthScore,
    required String scoreExplanation,
    required List<String> doctorQuestions,
    required String languageCode,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    final latestPrescription = prescriptions.isNotEmpty ? prescriptions.first : null;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SPECZ.CO',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 24,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        'Digital Eye-Care Companion Summary',
                        style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Date: ${DateTime.now().toString().split(' ')[0]}',
                        style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey800),
                      ),
                      pw.Text(
                        'Profile ID: ${profile.id}',
                        style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 12),

              // Patient Profile Info Box
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Patient Name: ${profile.name}', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                        pw.Text('Date of Birth / Age: ${profile.dob} (${profile.type})', style: pw.TextStyle(font: font, fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Gender: ${profile.gender}', style: pw.TextStyle(font: font, fontSize: 10)),
                        pw.Text('Relationship: ${profile.relationship}', style: pw.TextStyle(font: font, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Eye Health Score Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [

                        pw.Text('Eye Health Index Score', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blue900)),
                        pw.Text('$eyeHealthScore / 100', style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue800)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(scoreExplanation, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey800)),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Current Prescription Section
              pw.Text('Current Eye Prescription', style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.blue900)),
              pw.SizedBox(height: 6),
              if (latestPrescription != null) ...[
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Eye', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('SPH (Sphere)', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('CYL (Cylinder)', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Axis', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Add', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('PD', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Right (OD)', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${latestPrescription.rightSph ?? "-"}', style: pw.TextStyle(font: font, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${latestPrescription.rightCyl ?? "-"}', style: pw.TextStyle(font: font, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${latestPrescription.rightAxis ?? "-"}°', style: pw.TextStyle(font: font, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${latestPrescription.addPower ?? "0.0"}', style: pw.TextStyle(font: font, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${latestPrescription.pd ?? "-"} mm', style: pw.TextStyle(font: font, fontSize: 9))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Left (OS)', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${latestPrescription.leftSph ?? "-"}', style: pw.TextStyle(font: font, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${latestPrescription.leftCyl ?? "-"}', style: pw.TextStyle(font: font, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${latestPrescription.leftAxis ?? "-"}°', style: pw.TextStyle(font: font, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${latestPrescription.addPower ?? "0.0"}', style: pw.TextStyle(font: font, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${latestPrescription.pd ?? "-"} mm', style: pw.TextStyle(font: font, fontSize: 9))),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text('Doctor: ${latestPrescription.doctorName} (${latestPrescription.clinicName}) | Date: ${latestPrescription.prescriptionDate}', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700)),
              ] else ...[
                pw.Text('No active prescription recorded.', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
              ],
              pw.SizedBox(height: 16),

              // Medicines Section
              pw.Text('Active Medication & Eye Drops', style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.blue900)),
              pw.SizedBox(height: 6),
              if (medicines.isNotEmpty) ...[
                ...medicines.map((m) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Bullet(
                        text: '${m.name} (${m.type}) - ${m.dosage} [Schedule: ${m.times.join(", ")}]',
                        style: pw.TextStyle(font: font, fontSize: 9),
                      ),
                    )),
              ] else ...[
                pw.Text('No active eye drops or medicines scheduled.', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
              ],
              pw.SizedBox(height: 16),

              // AI Suggested Questions for Doctor
              pw.Text('Suggested Questions for Next Doctor Visit', style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.blue900)),
              pw.SizedBox(height: 6),
              ...doctorQuestions.map((q) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text('• $q', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey900)),
                  )),

              pw.Spacer(),

              // Legal Disclaimer Banner
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  border: pw.Border.all(color: PdfColors.amber300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  'DISCLAIMER: Specz.co helps organize personal eye-care records and reminders. It does not provide a medical diagnosis and does not replace an eye-care professional. Double-check all eye prescription values before ordering lenses.',
                  style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.amber900),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
