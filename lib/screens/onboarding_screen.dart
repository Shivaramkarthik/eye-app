import 'package:flutter/material.dart';
import '../utils/app_icons.dart';
import '../utils/app_theme.dart';
import '../models/profile_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class OnboardingScreen extends StatefulWidget {
  final UserModel user;
  final Function(ProfileModel) onProfileCreated;

  const OnboardingScreen({Key? key, required this.user, required this.onProfileCreated}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentStep = 1;

  final _nameController = TextEditingController();
  final _dobController = TextEditingController(text: "1994-08-10");
  String gender = 'Male';
  String profileType = 'Adult';
  String relationship = 'Self';

  String? knowsPrescriptionType; // 'Yes', 'No', 'Not sure'
  String? selectedPrescriptionType; // 'Myopia', 'Hypermetropia', 'Astigmatism', 'Presbyopia'
  List<String> selectedSymptoms = [];
  String? blurredVisionType; // 'Near', 'Distance', 'Both', 'Not sure'

  final List<String> technicalOptions = [
    'Myopia',
    'Hypermetropia',
    'Astigmatism',
    'Presbyopia',
    'Other',
    'Not sure'
  ];

  final List<String> symptomOptions = [
    'Blurred vision',
    'Headache',
    'Eye strain',
    'Watering eyes',
    'Eye pain',
    'Hazy vision',
    'Difficulty focusing',
    'No symptoms'
  ];

  Future<void> _submitProfile() async {
    if (_nameController.text.trim().isEmpty) return;

    final profile = ProfileModel(
      id: "prof_${DateTime.now().millisecondsSinceEpoch}",
      userId: widget.user.id,
      name: _nameController.text.trim(),
      dob: _dobController.text.trim(),
      gender: gender,
      type: profileType,
      relationship: relationship,
      prescriptionType: selectedPrescriptionType,
      symptoms: selectedSymptoms,
      blurredVisionType: blurredVisionType,
      createdAt: DateTime.now().toIso8601String(),
    );

    await DatabaseService.instance.insertProfile(profile);
    widget.onProfileCreated(profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text("Create Profile"),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Progress Bar
              Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: AppTheme.animFast,
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: currentStep >= 1 ? AppTheme.primaryGradient : null,
                        color: currentStep >= 1 ? null : AppTheme.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedContainer(
                      duration: AppTheme.animFast,
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: currentStep >= 2 ? AppTheme.primaryGradient : null,
                        color: currentStep >= 2 ? null : AppTheme.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (currentStep == 1) ...[
                const Text("Profile Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                const Text("Who is this profile for?", style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                const SizedBox(height: 24),

                // Adult vs Child Card Selectors
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          profileType = 'Adult';
                          relationship = 'Self';
                        }),
                        child: AnimatedContainer(
                          duration: AppTheme.animFast,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: profileType == 'Adult' ? AppTheme.primaryGradient : null,
                            color: profileType == 'Adult' ? null : Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                            boxShadow: profileType == 'Adult' ? AppTheme.primaryShadow : AppTheme.softShadow,
                            border: profileType == 'Adult' ? null : Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.person_rounded, size: 36, color: profileType == 'Adult' ? Colors.white : AppTheme.primary),
                              const SizedBox(height: 10),
                              Text("Adult Profile", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: profileType == 'Adult' ? Colors.white : AppTheme.textPrimary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          profileType = 'Child';
                          relationship = 'Child';
                        }),
                        child: AnimatedContainer(
                          duration: AppTheme.animFast,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: profileType == 'Child' ? AppTheme.primaryGradient : null,
                            color: profileType == 'Child' ? null : Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                            boxShadow: profileType == 'Child' ? AppTheme.primaryShadow : AppTheme.softShadow,
                            border: profileType == 'Child' ? null : Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.child_care_rounded, size: 36, color: profileType == 'Child' ? Colors.white : AppTheme.primary),
                              const SizedBox(height: 10),
                              Text("Child Profile", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: profileType == 'Child' ? Colors.white : AppTheme.textPrimary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _nameController,
                  decoration: AppTheme.inputDecoration(
                    label: "Name",
                    prefixIcon: Icons.badge_rounded,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _dobController,
                  decoration: AppTheme.inputDecoration(
                    label: "Date of Birth (YYYY-MM-DD)",
                    prefixIcon: Icons.calendar_today_rounded,
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: relationship,
                  decoration: AppTheme.inputDecoration(label: "Relationship", prefixIcon: Icons.family_restroom_rounded),
                  items: ['Self', 'Child', 'Spouse', 'Parent', 'Other']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) => setState(() => relationship = val!),
                ),
                const SizedBox(height: 28),
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
                      onPressed: _nameController.text.trim().isEmpty
                          ? null
                          : () => setState(() => currentStep = 2),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                      ),
                      child: const Text("Next: Symptoms & Eye Flow", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                ),
              ] else if (currentStep == 2) ...[
                const Text("Eye Prescription & Symptoms", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                const Text("Do you know your prescription type?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                const SizedBox(height: 16),

                Row(
                  children: ['Yes', 'No', 'Not sure'].map((option) {
                    bool isSelected = knowsPrescriptionType == option;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => knowsPrescriptionType = option),
                        child: AnimatedContainer(
                          duration: AppTheme.animFast,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppTheme.primaryGradient : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            border: isSelected ? null : Border.all(color: AppTheme.border),
                            boxShadow: isSelected ? AppTheme.primaryShadow : [],
                          ),
                          child: Center(
                            child: Text(
                              option,
                              style: TextStyle(fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppTheme.textPrimary),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // If YES -> Technical Options
                if (knowsPrescriptionType == 'Yes') ...[
                  const Text("Select technical prescription type:", style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: technicalOptions.map((opt) {
                      bool isSel = selectedPrescriptionType == opt;
                      return ChoiceChip(
                        label: Text(opt),
                        selected: isSel,
                        selectedColor: AppTheme.primary,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(color: isSel ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSel ? AppTheme.primary : AppTheme.border)),
                        onSelected: (_) => setState(() => selectedPrescriptionType = opt),
                      );
                    }).toList(),
                  ),
                ],

                // If NO / NOT SURE -> Symptom Flow
                if (knowsPrescriptionType == 'No' || knowsPrescriptionType == 'Not sure') ...[
                  const Text("Select visual symptoms experienced:", style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: symptomOptions.map((symp) {
                      bool isSel = selectedSymptoms.contains(symp);
                      return FilterChip(
                        label: Text(symp),
                        selected: isSel,
                        selectedColor: AppTheme.primary.withOpacity(0.15),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(color: isSel ? AppTheme.primary : AppTheme.textPrimary, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSel ? AppTheme.primary : AppTheme.border)),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedSymptoms.add(symp);
                            } else {
                              selectedSymptoms.remove(symp);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  if (selectedSymptoms.contains('Blurred vision')) ...[
                    const SizedBox(height: 20),
                    const Text("Blurred vision follow-up:", style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: blurredVisionType ?? 'Both',
                      decoration: AppTheme.inputDecoration(label: "Difficulty seeing..."),
                      items: ['Difficulty seeing nearby objects', 'Difficulty seeing distant objects', 'Difficulty seeing both near and far', 'Not sure']
                          .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) => setState(() => blurredVisionType = val),
                    ),
                  ],
                ],

                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => currentStep = 1),
                        child: const Text("Back"),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          boxShadow: AppTheme.primaryShadow,
                        ),
                        child: ElevatedButton(
                          onPressed: _submitProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                          ),
                          child: const Text("Save & Finish", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
