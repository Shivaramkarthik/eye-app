import 'package:flutter/material.dart';
import '../utils/app_icons.dart';
import '../utils/app_theme.dart';
import '../models/profile_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../widgets/medical_disclaimer_banner.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final UserModel user;
  final ProfileModel profile;
  final VoidCallback onProfileDeleted;
  final Function(ProfileModel updatedProfile)? onProfileUpdated;
  final VoidCallback onLogout;

  const ProfileSettingsScreen({
    Key? key,
    required this.user,
    required this.profile,
    required this.onProfileDeleted,
    this.onProfileUpdated,
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

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _relationships = ['Self', 'Child', 'Spouse', 'Parent', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _dobController = TextEditingController(text: widget.profile.dob);

    _gender = _genders.contains(widget.profile.gender) ? widget.profile.gender : 'Male';
    _relationship = _relationships.contains(widget.profile.relationship) ? widget.profile.relationship : 'Self';
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile name cannot be empty.")),
      );
      return;
    }

    try {
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
      widget.onProfileUpdated?.call(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile details updated successfully!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile: $e")),
      );
    }
  }

  void _confirmDeleteProfile() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Delete '${widget.profile.name}'?",
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: const Text(
            "Delete this profile permanently? This will delete all prescriptions, eye reports, reminders, notes, and history connected to it. This action cannot be undone.",
            style: TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textSecondary),
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
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Profile '${widget.profile.name}' deleted.")),
                );
                widget.onProfileDeleted();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              child: const Text("Delete Permanently", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Delete Account Permanently?",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: const Text(
            "Deleting your account will permanently wipe all profiles, prescriptions, eye drops, reminder schedules, and reports across your account. This action cannot be undone.",
            style: TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final dao = await DatabaseService.instance.userDao;
                await dao.softDeleteAccount(widget.user.id);
                if (!mounted) return;
                widget.onLogout();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              child: const Text("Permanently Delete Account", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text("Settings & Profile"),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Account & Plan Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: AppTheme.primaryShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              Text(
                                widget.user.email,
                                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Plan: ${widget.user.plan.toUpperCase()}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.user.isPlusActive ? AppTheme.accent : Colors.white24,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.user.isPlusActive ? "PLUS ACTIVE" : "FREE PLAN",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: widget.user.isPlusActive ? AppTheme.textPrimary : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Edit Active Profile Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Edit Active Profile", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: AppTheme.inputDecoration(label: "Profile Name", prefixIcon: Icons.badge_rounded),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _dobController,
                      decoration: AppTheme.inputDecoration(label: "Date of Birth (YYYY-MM-DD)", prefixIcon: Icons.calendar_today_rounded),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: AppTheme.inputDecoration(label: "Gender", prefixIcon: Icons.person_outline_rounded),
                      items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (val) => setState(() => _gender = val!),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _relationship,
                      decoration: AppTheme.inputDecoration(label: "Relationship", prefixIcon: Icons.family_restroom_rounded),
                      items: _relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) => setState(() => _relationship = val!),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                        ),
                        child: const Text("Update Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Settings List Items
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.notifications_active_rounded,
                      title: "Alerts & Notification Preferences",
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSettingsTile(
                      icon: Icons.privacy_tip_rounded,
                      title: "Terms of Service & Privacy Policy",
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSettingsTile(
                      icon: Icons.help_outline_rounded,
                      title: "Help & Support",
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const MedicalDisclaimerBanner(),

              const SizedBox(height: 24),

              // Delete Profile Button
              OutlinedButton.icon(
                onPressed: _confirmDeleteProfile,
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                label: Text("Delete '${widget.profile.name}' Profile Permanently", style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.error.withOpacity(0.4)),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                ),
              ),

              // Delete Account Button
              OutlinedButton.icon(
                onPressed: _confirmDeleteAccount,
                icon: const Icon(Icons.no_accounts_rounded, color: AppTheme.error),
                label: const Text("Delete My Specz Account", style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.error),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                ),
              ),

              const SizedBox(height: 12),

              // Logout Button
              Center(
                child: TextButton.icon(
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
                  label: const Text("Log Out", style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      ),
    );
  }
}
