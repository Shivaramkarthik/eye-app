import 'package:flutter/material.dart';
import '../utils/app_icons.dart';


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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Create Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Step Indicator
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      color: currentStep >= 1 ? const Color(0xFF0284C7) : Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      color: currentStep >= 2 ? const Color(0xFF0284C7) : Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (currentStep == 1) ...[
                const Text("Profile Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                const Text("Who is this profile for?", style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                const SizedBox(height: 20),

                // Adult vs Child Toggle
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          profileType = 'Adult';
                          relationship = 'Self';
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: profileType == 'Adult' ? const Color(0xFFE0F2FE) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: profileType == 'Adult' ? const Color(0xFF0284C7) : Colors.grey.shade300),
                          ),
                          child: const Column(
                            children: [
                              Icon(LucideIcons.user, size: 28, color: Color(0xFF0284C7)),
                              SizedBox(height: 6),
                              Text("Adult Profile", style: TextStyle(fontWeight: FontWeight.bold)),
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
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: profileType == 'Child' ? const Color(0xFFE0F2FE) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: profileType == 'Child' ? const Color(0xFF0284C7) : Colors.grey.shade300),
                          ),
                          child: const Column(
                            children: [
                              Icon(LucideIcons.baby, size: 28, color: Color(0xFF0284C7)),
                              SizedBox(height: 6),
                              Text("Child Profile", style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(LucideIcons.userCheck),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _dobController,
                  decoration: const InputDecoration(
                    labelText: "Date of Birth (YYYY-MM-DD)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(LucideIcons.calendar),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: relationship,
                  decoration: const InputDecoration(labelText: "Relationship", border: OutlineInputBorder()),
                  items: ['Self', 'Child', 'Spouse', 'Parent', 'Other']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) => setState(() => relationship = val!),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _nameController.text.trim().isEmpty
                        ? null
                        : () => setState(() => currentStep = 2),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                    child: const Text("Next: Symptom & Eye Flow", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else if (currentStep == 2) ...[
                const Text("Eye Prescription & Symptoms", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                const Text("Do you know your prescription type?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                const SizedBox(height: 14),

                Row(
                  children: ['Yes', 'No', 'Not sure'].map((option) {
                    bool isSelected = knowsPrescriptionType == option;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => knowsPrescriptionType = option),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? const Color(0xFF0284C7) : Colors.grey.shade300),
                          ),
                          child: Center(
                            child: Text(
                              option,
                              style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // If YES -> Technical Options
                if (knowsPrescriptionType == 'Yes') ...[
                  const Text("Select technical prescription type:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: technicalOptions.map((opt) {
                      bool isSel = selectedPrescriptionType == opt;
                      return ChoiceChip(
                        label: Text(opt),
                        selected: isSel,
                        selectedColor: const Color(0xFF0284C7),
                        labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black),
                        onSelected: (_) => setState(() => selectedPrescriptionType = opt),
                      );
                    }).toList(),
                  ),
                ],

                // If NO / NOT SURE -> Symptom Flow
                if (knowsPrescriptionType == 'No' || knowsPrescriptionType == 'Not sure') ...[
                  const Text("Select visual symptoms experienced:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: symptomOptions.map((symp) {
                      bool isSel = selectedSymptoms.contains(symp);
                      return FilterChip(
                        label: Text(symp),
                        selected: isSel,
                        selectedColor: const Color(0xFFE0F2FE),
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
                    const SizedBox(height: 16),
                    const Text("Blurred vision follow-up:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: blurredVisionType ?? 'Both',
                      decoration: const InputDecoration(labelText: "Difficulty seeing...", border: OutlineInputBorder()),
                      items: ['Difficulty seeing nearby objects', 'Difficulty seeing distant objects', 'Difficulty seeing both near and far', 'Not sure']
                          .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (val) => setState(() => blurredVisionType = val),
                    ),
                  ],
                ],

                const SizedBox(height: 24),
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
                      child: ElevatedButton(
                        onPressed: _submitProfile,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                        child: const Text("Save & Complete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
