import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../utils/app_icons.dart';

import 'package:printing/printing.dart';
import '../models/medicine_model.dart';
import '../models/prescription_model.dart';
import '../models/profile_model.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import '../services/entitlement_service.dart';
import '../services/i18n_service.dart';
import '../services/pdf_service.dart';

class ReportViewerScreen extends StatefulWidget {
  final UserModel user;
  final ProfileModel profile;
  final List<PrescriptionModel> prescriptions;
  final List<ReportModel> reports;
  final List<MedicineModel> medicines;
  final int eyeHealthScore;
  final String scoreExplanation;
  final List<String> doctorQuestions;
  final VoidCallback onUpgradeRequested;

  const ReportViewerScreen({
    super.key,
    required this.user,
    required this.profile,
    required this.prescriptions,
    required this.reports,
    required this.medicines,
    required this.eyeHealthScore,
    required this.scoreExplanation,
    required this.doctorQuestions,
    required this.onUpgradeRequested,
  });

  @override
  State<ReportViewerScreen> createState() => _ReportViewerScreenState();
}

class _ReportViewerScreenState extends State<ReportViewerScreen> {
  String selectedLanguage = 'en';
  Uint8List? pdfBytes;
  bool isGenerating = true;

  @override
  void initState() {
    super.initState();
    _buildPdf();
  }

  Future<void> _buildPdf() async {
    setState(() => isGenerating = true);
    final bytes = await PdfService.instance.generateProfileSummaryPdf(
      profile: widget.profile,
      prescriptions: widget.prescriptions,
      reports: widget.reports,
      medicines: widget.medicines,
      eyeHealthScore: widget.eyeHealthScore,
      scoreExplanation: widget.scoreExplanation,
      doctorQuestions: widget.doctorQuestions,
      languageCode: selectedLanguage,
    );

    setState(() {
      pdfBytes = bytes;
      isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool canDownload = EntitlementService.instance.canGeneratePdf(widget.user);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("PDF Report (${widget.profile.name})", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          // Language Switcher Dropdown
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButton<String>(
              value: selectedLanguage,
              underline: const SizedBox.shrink(),
              icon: const Icon(LucideIcons.globe, size: 20, color: Color(0xFF0284C7)),
              items: const [
                DropdownMenuItem(value: 'en', child: Text("English")),
                DropdownMenuItem(value: 'hi', child: Text("हिंदी")),
                DropdownMenuItem(value: 'es', child: Text("Español")),
                DropdownMenuItem(value: 'ta', child: Text("தமிழ்")),
              ],
              onChanged: (lang) {
                if (lang != null) {
                  setState(() => selectedLanguage = lang);
                  I18nService.instance.setLanguage(lang);
                  _buildPdf();
                }
              },
            ),
          ),
        ],
      ),
      body: isGenerating
          ? const Center(child: CircularProgressIndicator())
          : pdfBytes == null
              ? const Center(child: Text("Error generating PDF."))
              : Column(
                  children: [
                    if (!canDownload) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: const Color(0xFFFEF3C7),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.lock, size: 20, color: Color(0xFFD97706)),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                "PDF report export is a Specz Plus feature. Upgrade for ₹99/month to download full reports.",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: widget.onUpgradeRequested,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
                              child: const Text("Upgrade", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Expanded(
                      child: PdfPreview(
                        build: (format) => pdfBytes!,
                        allowPrinting: canDownload,
                        allowSharing: canDownload,
                        canChangePageFormat: false,
                      ),
                    ),
                  ],
                ),
    );
  }
}
