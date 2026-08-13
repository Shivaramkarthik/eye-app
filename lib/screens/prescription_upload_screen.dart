import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/app_icons.dart';
import '../utils/app_theme.dart';
import '../models/prescription_model.dart';
import '../models/profile_model.dart';
import '../models/user_model.dart';
import '../services/ai_ocr_service.dart';
import '../services/database_service.dart';
import '../widgets/missing_sph_warning_banner.dart';
import '../widgets/medical_disclaimer_banner.dart';
import '../widgets/prescription_confirmation_dialog.dart';

class PrescriptionUploadScreen extends StatefulWidget {
  final UserModel user;
  final ProfileModel profile;
  final VoidCallback onSaved;

  const PrescriptionUploadScreen({
    Key? key,
    required this.user,
    required this.profile,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<PrescriptionUploadScreen> createState() => _PrescriptionUploadScreenState();
}

class _PrescriptionUploadScreenState extends State<PrescriptionUploadScreen> {
  final _doctorController = TextEditingController(text: "Dr. Ananya Sharma");
  final _clinicController = TextEditingController(text: "ClearVision Specialty Clinic");
  final _dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);

  final _rightSphController = TextEditingController(text: "-2.25");
  final _rightCylController = TextEditingController(text: "-0.75");
  final _rightAxisController = TextEditingController(text: "180");

  final _leftSphController = TextEditingController(text: "-2.50");
  final _leftCylController = TextEditingController(text: "-0.50");
  final _leftAxisController = TextEditingController(text: "175");

  final _addPowerController = TextEditingController(text: "0.0");
  final _pdController = TextEditingController(text: "63.0");
  final _notesController = TextEditingController(text: "Anti-reflective coating recommended for computer use.");

  File? _imageFile;
  bool isOcrProcessing = false;
  bool showWarning = false;
  int uploadQueueCount = 0;

  void _openCameraScanModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  const Text(
                    "Camera Prescription Scanner",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Align prescription paper inside frame for AI extraction",
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primary, width: 2),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.primary, width: 3), left: BorderSide(color: AppTheme.primary, width: 3)))),
                                      Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.primary, width: 3), right: BorderSide(color: AppTheme.primary, width: 3)))),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.primary, width: 3), left: BorderSide(color: AppTheme.primary, width: 3)))),
                                      Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.primary, width: 3), right: BorderSide(color: AppTheme.primary, width: 3)))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isOcrProcessing)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(width: 48, height: 48, child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3)),
                                SizedBox(height: 16),
                                Text("Analyzing with Gemini AI OCR...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              ],
                            )
                          else
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.center_focus_strong_rounded, size: 64, color: Colors.white38),
                                SizedBox(height: 12),
                                Text("Tap Shutter Button to Snap", style: TextStyle(color: Colors.white60, fontSize: 13)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.flash_on_rounded, color: Colors.white70),
                          onPressed: () {},
                        ),
                        GestureDetector(
                          onTap: isOcrProcessing
                              ? null
                              : () async {
                                  setModalState(() => isOcrProcessing = true);
                                  final result = await AiOcrService.instance.extractPrescriptionData("camera_photo.jpg");
                                  if (!mounted) return;
                                  setState(() {
                                    if (result.rightSph != null) _rightSphController.text = result.rightSph.toString();
                                    if (result.rightCyl != null) _rightCylController.text = result.rightCyl.toString();
                                    if (result.rightAxis != null) _rightAxisController.text = result.rightAxis.toString();
                                    if (result.leftSph != null) _leftSphController.text = result.leftSph.toString();
                                    if (result.leftCyl != null) _leftCylController.text = result.leftCyl.toString();
                                    if (result.leftAxis != null) _leftAxisController.text = result.leftAxis.toString();
                                    if (result.pd != null) _pdController.text = result.pd.toString();
                                    if (result.doctorName.isNotEmpty) _doctorController.text = result.doctorName;
                                    if (result.clinicName.isNotEmpty) _clinicController.text = result.clinicName;
                                    if (result.notes.isNotEmpty) _notesController.text = result.notes;
                                  });
                                  setModalState(() => isOcrProcessing = false);
                                  Navigator.pop(ctx);
                                  _showOcrConfirmationDialog(result);
                                },
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primary,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 16)],
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.photo_library_rounded, color: Colors.white70),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            _runAiOcrScan();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _runAiOcrScan() async {
    setState(() => isOcrProcessing = true);
    final imagePath = _imageFile?.path ?? "camera_scan.jpg";
    final result = await AiOcrService.instance.extractPrescriptionData(imagePath);
    if (!mounted) return;
    setState(() => isOcrProcessing = false);
    _showOcrConfirmationDialog(result);
  }

  void _showOcrConfirmationDialog(AiOcrResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PrescriptionConfirmationDialog(
        ocrResult: result,
        onConfirmed: (confirmedData) {
          setState(() {
            if (confirmedData['rightSph'] != null) _rightSphController.text = confirmedData['rightSph'].toString();
            if (confirmedData['rightCyl'] != null) _rightCylController.text = confirmedData['rightCyl'].toString();
            if (confirmedData['rightAxis'] != null) _rightAxisController.text = confirmedData['rightAxis'].toString();

            if (confirmedData['leftSph'] != null) _leftSphController.text = confirmedData['leftSph'].toString();
            if (confirmedData['leftCyl'] != null) _leftCylController.text = confirmedData['leftCyl'].toString();
            if (confirmedData['leftAxis'] != null) _leftAxisController.text = confirmedData['leftAxis'].toString();

            if (confirmedData['addPower'] != null) _addPowerController.text = confirmedData['addPower'].toString();
            if (confirmedData['pd'] != null) _pdController.text = confirmedData['pd'].toString();

            if ((confirmedData['doctorName'] as String?)?.isNotEmpty == true) _doctorController.text = confirmedData['doctorName'];
            if ((confirmedData['clinicName'] as String?)?.isNotEmpty == true) _clinicController.text = confirmedData['clinicName'];
          });
        },
      ),
    );
  }

  Future<void> _savePrescription() async {
    double? rSph = double.tryParse(_rightSphController.text.trim());
    double? rCyl = double.tryParse(_rightCylController.text.trim());
    double? lSph = double.tryParse(_leftSphController.text.trim());
    double? lCyl = double.tryParse(_leftCylController.text.trim());

    if (rSph == null || lSph == null) {
      setState(() => showWarning = true);
      return;
    }

    final prescription = PrescriptionModel(
      id: "presc_${DateTime.now().millisecondsSinceEpoch}",
      profileId: widget.profile.id,
      userId: widget.user.id,
      prescriptionDate: _dateController.text,
      doctorName: _doctorController.text,
      clinicName: _clinicController.text,
      rightSph: rSph,
      rightCyl: rCyl,
      rightAxis: int.tryParse(_rightAxisController.text),
      leftSph: lSph,
      leftCyl: lCyl,
      leftAxis: int.tryParse(_leftAxisController.text),
      addPower: double.tryParse(_addPowerController.text),
      pd: double.tryParse(_pdController.text),
      notes: _notesController.text,
      isCurrent: true,
      createdAt: DateTime.now().toIso8601String(),
    );

    await DatabaseService.instance.insertPrescription(prescription);
    if (!mounted) return;
    widget.onSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text("Add Prescription (${widget.profile.name})", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Camera Scan Banner Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded, size: 24, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Scan with Camera / Gallery", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                          SizedBox(height: 2),
                          Text("Extract SPH, CYL & Axis automatically with AI OCR", style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openCameraScanModal,
                      icon: const Icon(Icons.camera_alt_rounded, size: 16),
                      label: const Text("Scan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              const MedicalDisclaimerBanner(),
              const SizedBox(height: 16),

              if (showWarning) ...[
                const MissingSphWarningBanner(),
                const SizedBox(height: 16),
              ],

              // Right Eye (OD) Section
              const Text("Right Eye (OD)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: _rightSphController, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: AppTheme.inputDecoration(label: "SPH (Sphere)"))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _rightCylController, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: AppTheme.inputDecoration(label: "CYL (Cylinder)"))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _rightAxisController, keyboardType: TextInputType.number, decoration: AppTheme.inputDecoration(label: "Axis (°)"))),
                ],
              ),

              const SizedBox(height: 20),

              // Left Eye (OS) Section
              const Text("Left Eye (OS)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: _leftSphController, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: AppTheme.inputDecoration(label: "SPH (Sphere)"))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _leftCylController, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: AppTheme.inputDecoration(label: "CYL (Cylinder)"))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _leftAxisController, keyboardType: TextInputType.number, decoration: AppTheme.inputDecoration(label: "Axis (°)"))),
                ],
              ),

              const SizedBox(height: 20),

              // Additional Details
              Row(
                children: [
                  Expanded(child: TextField(controller: _addPowerController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: AppTheme.inputDecoration(label: "ADD Power"))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _pdController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: AppTheme.inputDecoration(label: "PD (mm)"))),
                ],
              ),

              const SizedBox(height: 14),
              TextField(controller: _doctorController, decoration: AppTheme.inputDecoration(label: "Doctor Name", prefixIcon: Icons.badge_rounded)),
              const SizedBox(height: 14),
              TextField(controller: _clinicController, decoration: AppTheme.inputDecoration(label: "Clinic / Hospital Name", prefixIcon: Icons.local_hospital_rounded)),
              const SizedBox(height: 14),
              TextField(controller: _dateController, decoration: AppTheme.inputDecoration(label: "Prescription Date (YYYY-MM-DD)", prefixIcon: Icons.calendar_today_rounded)),
              const SizedBox(height: 14),
              TextField(controller: _notesController, maxLines: 2, decoration: AppTheme.inputDecoration(label: "Notes & Recommendations", prefixIcon: Icons.notes_rounded)),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _savePrescription,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium))),
                  child: const Text("Save Prescription Record", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
