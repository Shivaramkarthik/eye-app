import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../models/medicine_model.dart';
import '../models/profile_model.dart';
import '../models/user_model.dart';
import '../services/audio_haptic_service.dart';
import '../services/database_service.dart';
import '../services/notification_scheduler.dart';
import '../services/notification_service.dart';

class MedicineTrackerScreen extends StatefulWidget {
  final UserModel user;
  final ProfileModel profile;
  final VoidCallback onUpdated;

  const MedicineTrackerScreen({
    super.key,
    required this.user,
    required this.profile,
    required this.onUpdated,
  });

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
  List<String> selectedTimes = ['08:00 AM', '08:00 PM'];

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }


  Future<void> _loadMedicines() async {
    final list = await DatabaseService.instance.getMedicines(widget.profile.id);
    setState(() {
      medicines = list;
      isLoading = false;
    });
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  Future<void> _addMedicine() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a medicine or eye drop name.")),
      );
      return;
    }

    final med = MedicineModel(
      id: "med_${DateTime.now().millisecondsSinceEpoch}",
      profileId: widget.profile.id,
      userId: widget.user.id,
      name: _nameController.text.trim(),
      type: selectedType,
      dosage: _dosageController.text.trim(),
      startDate: DateTime.now().toString().split(' ')[0],
      times: selectedTimes.isNotEmpty ? List.from(selectedTimes) : ['08:00 AM'],
      tone: selectedTone,
      vibrationEnabled: vibrationEnabled,
      active: true,
      createdAt: DateTime.now().toIso8601String(),
    );

    await DatabaseService.instance.insertMedicine(med);
    await NotificationScheduler.instance.scheduleMedicine(med);
    try {
      await NotificationService.instance.showImmediateTestNotification(med);
    } catch (_) {}
    _nameController.clear();
    if (!mounted) return;
    final nav = Navigator.of(context);
    nav.pop(); // close modal
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
    selectedTimes = ['08:00 AM', '08:00 PM'];
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              gradient: AppTheme.primaryGradient,
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
                              initialValue: selectedType,
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
                      const SizedBox(height: 16),

                      const Text(
                        "Alarm Times",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...selectedTimes.map((t) => Chip(
                                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                side: BorderSide.none,
                                avatar: const Icon(Icons.alarm_rounded, size: 16, color: AppTheme.primary),
                                label: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 13)),
                                deleteIcon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textSecondary),
                                onDeleted: () {
                                  if (selectedTimes.length > 1) {
                                    setModalState(() => selectedTimes.remove(t));
                                  }
                                },
                              )),
                          ActionChip(
                            avatar: const Icon(Icons.add_alarm_rounded, size: 16, color: AppTheme.primary),
                            label: const Text("+ Add Custom Time", style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppTheme.primary),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                final formatted = _formatTimeOfDay(picked);
                                if (!selectedTimes.contains(formatted)) {
                                  setModalState(() => selectedTimes.add(formatted));
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: selectedTone,
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
                          activeThumbColor: AppTheme.primary,
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
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateTime.now().toString().split(' ')[0];

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text("${widget.profile.name}'s Eye Drop Schedule"),
        actions: [
          IconButton(
            tooltip: "Test Alarm Chime Sound",
            icon: const Icon(Icons.volume_up_rounded, color: AppTheme.primary),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await AudioHapticService.instance.playNotificationTone("Soft Chime");
              await AudioHapticService.instance.triggerVibration();
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text("Alarm Sound & Vibration Tested!")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_alarm_rounded, color: AppTheme.primary),
            onPressed: _showAddMedicineModal,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMedicineModal,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Add Drop Alarm"),
        backgroundColor: AppTheme.primary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : medicines.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.water_drop_rounded, size: 56, color: AppTheme.primary),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "No Eye Drops Scheduled",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Schedule your daily eye drop reminders and custom alarm times to protect your vision.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddMedicineModal,
                          icon: const Icon(Icons.add_alarm_rounded),
                          label: const Text("Set First Alarm"),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: medicines.length,
                  itemBuilder: (context, index) {
                    final med = medicines[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.water_drop_rounded, color: AppTheme.primary, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      med.name,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${med.type} · ${med.dosage}",
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.textHint, size: 20),
                                  onPressed: () async {
                                    await NotificationScheduler.instance.cancelMedicine(med);
                                    await DatabaseService.instance.deleteMedicine(med.id);
                                    _loadMedicines();
                                    widget.onUpdated();
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          const Text("Daily Alarm Times:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: med.times.map((t) {
                              final isTaken = med.isLoggedFor(todayStr, t);
                              return InkWell(
                                onTap: () => _toggleLog(med, t),
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isTaken ? AppTheme.success.withValues(alpha: 0.15) : AppTheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isTaken ? AppTheme.success : AppTheme.border,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isTaken ? Icons.check_circle_rounded : Icons.access_time_rounded,
                                        size: 16,
                                        color: isTaken ? AppTheme.success : AppTheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        t,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isTaken ? AppTheme.success : AppTheme.textPrimary,
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
                    );
                  },
                ),
    );
  }
}
