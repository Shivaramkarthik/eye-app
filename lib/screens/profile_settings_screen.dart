import 'package:flutter/material.dart';
import '../utils/app_icons.dart';


import '../models/profile_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../widgets/medical_disclaimer_banner.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final UserModel user;
  final ProfileModel profile;
  final VoidCallback onProfileDeleted;
  final VoidCallback onLogout;

  const ProfileSettingsScreen({
    Key? key,
    required this.user,
    required this.profile,
    required this.onProfileDeleted,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late String _gender;
  late String _relationship;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _dobController = TextEditingController(text: widget.profile.dob);
    _gender = widget.profile.gender;
    _relationship = widget.profile.relationship;
  }

  Future<void> _updateProfile() async {
    final updated = ProfileModel(
      id: widget.profile.id,
      userId: widget.profile.userId,
      name: _nameController.text.trim(),
      dob: _dobController.text.trim(),
      gender: _gender,
      type: widget.profile.type,
      relationship: _relationship,
      prescriptionType: widget.profile.prescriptionType,
      symptoms: widget.profile.symptoms,
      blurredVisionType: widget.profile.blurredVisionType,
      createdAt: widget.profile.createdAt,
    );

    await DatabaseService.instance.updateProfile(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile details updated successfully!")),
    );
  }

  /// Permanent profile deletion safety flow
  void _confirmDeleteProfile() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(LucideIcons.alertTriangle, color: Color(0xFFDC2626)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Delete '${widget.profile.name}'?",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            "Delete this profile permanently? This will delete all prescriptions, eye reports, reminders, notes, and history connected to it. This action cannot be undone and will immediately free up your profile slot.",
            style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await DatabaseService.instance.deleteProfileCascade(widget.profile.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Profile '${widget.profile.name}' deleted. Slot freed immediately.")),
                );
                widget.onProfileDeleted();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              child: const Text("Delete Permanently", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Profile Settings", style: TextStyle(fontWeight: FontWeight.bold)),
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
              // User Account Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFE0F2FE),
                      child: const Icon(LucideIcons.user, color: Color(0xFF0284C7)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(widget.user.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          Text(widget.user.email, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.user.isPlusActive ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.user.isPlusActive ? "Specz Plus Active" : "Free Plan (1 Profile Limit)",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: widget.user.isPlusActive ? const Color(0xFFD97706) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Edit Profile Fields
              const Text("Edit Active Profile", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Profile Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dobController,
                decoration: const InputDecoration(labelText: "Date of Birth (YYYY-MM-DD)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: "Gender", border: OutlineInputBorder()),
                items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => _gender = val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _relationship,
                decoration: const InputDecoration(labelText: "Relationship", border: OutlineInputBorder()),
                items: ['Self', 'Child', 'Spouse', 'Parent', 'Other'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) => setState(() => _relationship = val!),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                  child: const Text("Update Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 20),

              // Preferences & Links
              ListTile(
                leading: const Icon(LucideIcons.bell, color: Color(0xFF0284C7)),
                title: const Text("Alerts & Notification Preferences"),
                trailing: const Icon(LucideIcons.chevronRight, size: 18),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(LucideIcons.fileText, color: Color(0xFF0284C7)),
                title: const Text("Terms of Service & Privacy Policy"),
                trailing: const Icon(LucideIcons.chevronRight, size: 18),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(LucideIcons.helpCircle, color: Color(0xFF0284C7)),
                title: const Text("Help & Support"),
                trailing: const Icon(LucideIcons.chevronRight, size: 18),
                onTap: () {},
              ),

              const SizedBox(height: 24),
              const MedicalDisclaimerBanner(),

              const SizedBox(height: 24),

              // Permanent Delete Button
              OutlinedButton.icon(
                onPressed: _confirmDeleteProfile,
                icon: const Icon(LucideIcons.trash2, color: Color(0xFFDC2626)),
                label: Text("Delete '${widget.profile.name}' Profile Permanently", style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),

              const SizedBox(height: 12),

              // Logout Button
              TextButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(LucideIcons.logOut, color: Color(0xFF64748B)),
                label: const Text("Log Out", style: TextStyle(color: Color(0xFF64748B))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
