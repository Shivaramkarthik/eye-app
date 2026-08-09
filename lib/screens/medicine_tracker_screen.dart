import 'package:flutter/material.dart';
import '../utils/app_icons.dart';
import '../utils/app_theme.dart';
import '../models/medicine_model.dart';
import '../models/profile_model.dart';
import '../models/user_model.dart';
import '../services/audio_haptic_service.dart';
import '../services/database_service.dart';

class MedicineTrackerScreen extends StatefulWidget {
  final UserModel user;
  final ProfileModel profile;
  final VoidCallback onUpdated;

  const MedicineTrackerScreen({
    Key? key,
    required this.user,
    required this.profile,
    required this.onUpdated,
  }) : super(key: key);

  @override
  State<MedicineTrackerScreen> createState() => _MedicineTrackerScreenState();
}

class _MedicineTrackerScreenState extends State<MedicineTrackerScreen> {
  List<MedicineModel> medicines = [];
  bool isLoading = true;

  final _nameController = TextEditingController();
  final _dosageController = TextEditingController(text: "1 drop in both eyes");
  String selectedType = 'Drop';
  String selectedTone = 'Soft Chime';
  bool vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    final list = await DatabaseService.instance.getMedicines(widget.profile.id);
    setState(() {
      medicines = list;
      isLoading = false;
    });
  }

  Future<void> _addMedicine() async {
    if (_nameController.text.trim().isEmpty) return;

    final med = MedicineModel(
      id: "med_${DateTime.now().millisecondsSinceEpoch}",
      profileId: widget.profile.id,
      userId: widget.user.id,
      name: _nameController.text.trim(),
      type: selectedType,
      dosage: _dosageController.text.trim(),
      startDate: DateTime.now().toString().split(' ')[0],
      times: ['08:00 AM', '08:00 PM'],
      tone: selectedTone,
      vibrationEnabled: vibrationEnabled,
      active: true,
      createdAt: DateTime.now().toIso8601String(),
    );

    await DatabaseService.instance.insertMedicine(med);
    _nameController.clear();
    if (!mounted) return;
    Navigator.pop(context); // close modal
    _loadMedicines();
    widget.onUpdated();
  }

  Future<void> _toggleLog(MedicineModel med, String timeKey) async {
    final logKey = "${DateTime.now().toString().split(' ')[0]}_$timeKey";
    await DatabaseService.instance.toggleMedicineLog(med.id, logKey);

    await AudioHapticService.instance.playNotificationTone(med.tone);
    if (med.vibrationEnabled) {
      await AudioHapticService.instance.triggerVibration();
    }

    _loadMedicines();
    widget.onUpdated();
  }

  void _showAddMedicineModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: 24,
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppTheme.successGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Schedule Eye Drop / Medicine",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: AppTheme.inputDecoration(
                        label: "Medicine / Drop Name",
                        prefixIcon: Icons.medication_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedType,
                            decoration: AppTheme.inputDecoration(label: "Type"),
                            items: ['Drop', 'Tablet', 'Ointment', 'Custom']
                                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                            onChanged: (val) => setModalState(() => selectedType = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _dosageController,
                            decoration: AppTheme.inputDecoration(label: "Dosage"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedTone,
                      decoration: AppTheme.inputDecoration(
                        label: "Notification Sound",
                        prefixIcon: Icons.volume_up_rounded,
                      ),
                      items: ['Soft Chime', 'Gentle Bell', 'Alert Beep']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) => setModalState(() => selectedTone = val!),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: SwitchListTile(
                        title: const Text("Vibration Mode", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text("Vibrate on reminder alert", style: TextStyle(fontSize: 12)),
                        secondary: Icon(Icons.vibration_rounded, color: vibrationEnabled ? AppTheme.primary : AppTheme.textHint),
                        value: vibrationEnabled,
                        activeColor: AppTheme.primary,
                        onChanged: (val) => setModalState(() => vibrationEnabled = val),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          boxShadow: AppTheme.primaryShadow,
                        ),
                        child: ElevatedButton(
                          onPressed: _addMedicine,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                          ),
                          child: const Text("Save Schedule", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String todayStr = DateTime.now().toString().split(' ')[0];

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text("Eye Drops · ${widget.profile.name}"),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppTheme.primaryShadow,
        ),
        child: FloatingActionButton.extended(
          onPressed: _showAddMedicineModal,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text("Add Drop", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : medicines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.water_drop_rounded, size: 48, color: AppTheme.primary.withOpacity(0.4)),
                      ),
                      const SizedBox(height: 16),
                      const Text("No eye drop reminders yet", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      const SizedBox(height: 6),
                      const Text("Tap '+ Add Drop' to set up daily schedules", style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: medicines.length,
                  itemBuilder: (context, index) {
                    final med = medicines[index];
                    final Color accentColor = med.type == 'Drop'
                        ? AppTheme.primary
                        : med.type == 'Tablet'
                            ? AppTheme.accent
                            : AppTheme.success;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Row(
                        children: [
                          // Left accent bar
                          Container(
                            width: 4,
                            height: 130,
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: accentColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          med.type == 'Drop' ? Icons.water_drop_rounded : Icons.medication_rounded,
                                          color: accentColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(med.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                                            const SizedBox(height: 2),
                                            Text("${med.type} · ${med.dosage}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Tone and vibration info
                                  Row(
                                    children: [
                                      Icon(Icons.volume_up_rounded, size: 14, color: AppTheme.textHint),
                                      const SizedBox(width: 4),
                                      Text(med.tone, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                      const SizedBox(width: 14),
                                      Icon(Icons.vibration_rounded, size: 14, color: med.vibrationEnabled ? AppTheme.primary : AppTheme.textHint),
                                      const SizedBox(width: 4),
                                      Text(med.vibrationEnabled ? "On" : "Off", style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Time toggle buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: med.times.map((t) {
                                      final logKey = "${todayStr}_$t";
                                      bool isDone = med.completedLogs.contains(logKey);
                                      return GestureDetector(
                                        onTap: () => _toggleLog(med, t),
                                        child: AnimatedContainer(
                                          duration: AppTheme.animFast,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          decoration: BoxDecoration(
                                            gradient: isDone ? AppTheme.successGradient : null,
                                            color: isDone ? null : AppTheme.surface,
                                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                            boxShadow: isDone
                                                ? [BoxShadow(color: AppTheme.success.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]
                                                : [],
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isDone ? Icons.check_circle_rounded : Icons.access_time_rounded,
                                                size: 18,
                                                color: isDone ? Colors.white : AppTheme.textSecondary,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                t,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDone ? Colors.white : AppTheme.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
