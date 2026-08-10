import 'package:flutter/material.dart';
import '../services/ai_ocr_service.dart';
import '../utils/app_theme.dart';

class PrescriptionConfirmationDialog extends StatefulWidget {
  final AiOcrResult ocrResult;
  final Function(Map<String, dynamic> confirmedData) onConfirmed;

  const PrescriptionConfirmationDialog({
    Key? key,
    required this.ocrResult,
    required this.onConfirmed,
  }) : super(key: key);

  @override
  State<PrescriptionConfirmationDialog> createState() => _PrescriptionConfirmationDialogState();
}

class _PrescriptionConfirmationDialogState extends State<PrescriptionConfirmationDialog> {
  late TextEditingController _rSphController;
  late TextEditingController _rCylController;
  late TextEditingController _rAxisController;

  late TextEditingController _lSphController;
  late TextEditingController _lCylController;
  late TextEditingController _lAxisController;

  late TextEditingController _addController;
  late TextEditingController _pdController;
  late TextEditingController _doctorController;
  late TextEditingController _clinicController;

  bool rCylZeroConfirmed = false;
  bool lCylZeroConfirmed = false;

  @override
  void initState() {
    super.initState();
    _rSphController = TextEditingController(text: widget.ocrResult.rightSph?.toString() ?? '');
    _rCylController = TextEditingController(text: widget.ocrResult.rightCyl?.toString() ?? '');
    _rAxisController = TextEditingController(text: widget.ocrResult.rightAxis?.toString() ?? '');

    _lSphController = TextEditingController(text: widget.ocrResult.leftSph?.toString() ?? '');
    _lCylController = TextEditingController(text: widget.ocrResult.leftCyl?.toString() ?? '');
    _lAxisController = TextEditingController(text: widget.ocrResult.leftAxis?.toString() ?? '');

    _addController = TextEditingController(text: widget.ocrResult.addPower?.toString() ?? '0.0');
    _pdController = TextEditingController(text: widget.ocrResult.pd?.toString() ?? '63.0');
    _doctorController = TextEditingController(text: widget.ocrResult.doctorName);
    _clinicController = TextEditingController(text: widget.ocrResult.clinicName);
  }

  @override
  void dispose() {
    _rSphController.dispose();
    _rCylController.dispose();
    _rAxisController.dispose();
    _lSphController.dispose();
    _lCylController.dispose();
    _lAxisController.dispose();
    _addController.dispose();
    _pdController.dispose();
    _doctorController.dispose();
    _clinicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isRightMissing = _rSphController.text.isEmpty || _rCylController.text.isEmpty;
    bool isLeftMissing = _lSphController.text.isEmpty || _lCylController.text.isEmpty;
    bool hasMissingFields = isRightMissing || isLeftMissing;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fact_check_rounded, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Review OCR Extracted Prescription",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Please verify the extracted eye values against your original paper prescription before saving.",
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            if (hasMissingFields)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warning),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Some prescription values could not be detected. Please check the original prescription and enter the missing values before saving.",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),

            // RIGHT EYE (OD)
            _buildEyeHeader("RIGHT EYE (OD)", widget.ocrResult.rightSphConfidence),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildValueField("SPH", _rSphController, widget.ocrResult.rightSphConfidence)),
                const SizedBox(width: 8),
                Expanded(child: _buildValueField("CYL", _rCylController, widget.ocrResult.rightCylConfidence)),
                const SizedBox(width: 8),
                Expanded(child: _buildValueField("AXIS", _rAxisController, widget.ocrResult.rightAxisConfidence)),
              ],
            ),
            const SizedBox(height: 16),

            // LEFT EYE (OS)
            _buildEyeHeader("LEFT EYE (OS)", widget.ocrResult.leftSphConfidence),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildValueField("SPH", _lSphController, widget.ocrResult.leftSphConfidence)),
                const SizedBox(width: 8),
                Expanded(child: _buildValueField("CYL", _lCylController, widget.ocrResult.leftCylConfidence)),
                const SizedBox(width: 8),
                Expanded(child: _buildValueField("AXIS", _lAxisController, widget.ocrResult.leftAxisConfidence)),
              ],
            ),
            const SizedBox(height: 16),

            // Additional details
            Row(
              children: [
                Expanded(child: _buildTextField("ADD Power", _addController)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField("PD (mm)", _pdController)),
              ],
            ),
            const SizedBox(height: 10),
            _buildTextField("Doctor Name", _doctorController),
            const SizedBox(height: 10),
            _buildTextField("Clinic / Hospital", _clinicController),
            const SizedBox(height: 16),

            // Disclaimer Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Text(
                "AI/OCR can make mistakes. Please double-check all prescription values against the original prescription before saving. Specz.co is not a substitute for professional medical advice.",
                style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    final data = {
                      'rightSph': double.tryParse(_rSphController.text),
                      'rightCyl': double.tryParse(_rCylController.text),
                      'rightAxis': int.tryParse(_rAxisController.text),
                      'leftSph': double.tryParse(_lSphController.text),
                      'leftCyl': double.tryParse(_lCylController.text),
                      'leftAxis': int.tryParse(_lAxisController.text),
                      'addPower': double.tryParse(_addController.text),
                      'pd': double.tryParse(_pdController.text),
                      'doctorName': _doctorController.text,
                      'clinicName': _clinicController.text,
                    };
                    widget.onConfirmed(data);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check_rounded, color: Colors.white),
                  label: const Text("Confirm & Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEyeHeader(String title, double confidence) {
    bool high = confidence >= 0.90;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: high ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            high ? "✓ High Confidence (${(confidence * 100).toInt()}%)" : "⚠ Needs Review (${(confidence * 100).toInt()}%)",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: high ? AppTheme.success : AppTheme.warning),
          ),
        ),
      ],
    );
  }

  Widget _buildValueField(String label, TextEditingController controller, double confidence) {
    bool empty = controller.text.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            hintText: "Missing",
            hintStyle: const TextStyle(color: AppTheme.error, fontSize: 11),
            filled: true,
            fillColor: empty ? AppTheme.error.withValues(alpha: 0.05) : AppTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: empty ? AppTheme.error : AppTheme.divider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
          ),
        ),
      ],
    );
  }
}
