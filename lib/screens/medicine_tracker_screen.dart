import 'package:flutter/material.dart';
import '../utils/app_icons.dart';


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

    // Audio & vibration alert response
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Schedule Eye Drop / Medicine", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Medicine / Drop Name", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: const InputDecoration(labelText: "Type", border: OutlineInputBorder()),
                          items: ['Drop', 'Tablet', 'Ointment', 'Custom']
                              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (val) => setModalState(() => selectedType = val!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _dosageController,
                          decoration: const InputDecoration(labelText: "Dosage", border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Notification Tone Selector
                  DropdownButtonFormField<String>(
                    value: selectedTone,
                    decoration: const InputDecoration(
                      labelText: "Notification Sound Tone",
                      prefixIcon: Icon(LucideIcons.volume2),
                      border: OutlineInputBorder(),
                    ),
                    items: ['Soft Chime', 'Gentle Bell', 'Alert Beep']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) => setModalState(() => selectedTone = val!),
                  ),
                  const SizedBox(height: 10),

                  // Vibration Mode Toggle
                  SwitchListTile(
                    title: const Text("Vibration Mode"),
                    subtitle: const Text("Vibrate device on reminder alert"),
                    secondary: const Icon(LucideIcons.vibrate),
                    value: vibrationEnabled,
                    onChanged: (val) => setModalState(() => vibrationEnabled = val),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _addMedicine,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                      child: const Text("Save Schedule", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    String todayStr = DateTime.now().toString().split(' ')[0];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Eye Drops & Reminders (${widget.profile.name})", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMedicineModal,
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text("Add Drop", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : medicines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.droplets, size: 48, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      const Text("No eye drop reminders set yet.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 4),
                      const Text("Tap '+ Add Drop' to set up daily medicine schedules.", style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: medicines.length,
                  itemBuilder: (context, index) {
                    final med = medicines[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                                child: Icon(
                                  med.type == 'Drop' ? LucideIcons.droplet : LucideIcons.pill,
                                  color: const Color(0xFF0284C7),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(med.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                    Text("${med.type} • ${med.dosage}", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(LucideIcons.volume2, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(med.tone, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              const SizedBox(width: 12),
                              Icon(LucideIcons.vibrate, size: 14, color: med.vibrationEnabled ? const Color(0xFF0284C7) : Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(med.vibrationEnabled ? "Vibration On" : "Vibration Off", style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: med.times.map((t) {
                              final logKey = "${todayStr}_$t";
                              bool isDone = med.completedLogs.contains(logKey);
                              return GestureDetector(
                                onTap: () => _toggleLog(med, t),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: isDone ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isDone ? LucideIcons.checkCircle : LucideIcons.clock,
                                        size: 16,
                                        color: isDone ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        t,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isDone ? const Color(0xFF15803D) : const Color(0xFF334155),
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
