import 'package:flutter/material.dart';
import '../utils/app_icons.dart';


import '../models/user_model.dart';
import '../models/profile_model.dart';
import '../models/prescription_model.dart';
import '../models/report_model.dart';
import '../models/medicine_model.dart';
import '../services/database_service.dart';
import '../services/ai_ocr_service.dart';
import '../services/entitlement_service.dart';
import '../widgets/profile_switcher_bar.dart';
import '../widgets/eye_health_score_card.dart';
import '../widgets/academic_bw_chart.dart';
import '../widgets/ai_doctor_questions_card.dart';
import '../widgets/medical_disclaimer_banner.dart';
import 'prescription_upload_screen.dart';
import 'medicine_tracker_screen.dart';
import 'premium_upgrade_screen.dart';
import 'profile_settings_screen.dart';
import 'report_viewer_screen.dart';
import 'onboarding_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback onLogout;

  const DashboardScreen({
    Key? key,
    required this.user,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentBottomNavIndex = 0;

  late UserModel currentUser;
  List<ProfileModel> profiles = [];
  ProfileModel? selectedProfile;

  List<PrescriptionModel> prescriptions = [];
  List<ReportModel> reports = [];
  List<MedicineModel> medicines = [];

  bool isLoading = true;

  int eyeHealthScore = 85;
  String scoreExplanation = "";
  List<String> doctorQuestions = [];

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    final dbUser = await DatabaseService.instance.getUser(currentUser.id);
    if (dbUser != null) currentUser = dbUser;

    final profs = await DatabaseService.instance.getProfiles(currentUser.id);
    profiles = profs;

    if (profiles.isNotEmpty) {
      if (selectedProfile == null || !profiles.any((p) => p.id == selectedProfile!.id)) {
        selectedProfile = profiles.first;
      }
    } else {
      selectedProfile = null;
    }

    if (selectedProfile != null) {
      prescriptions = await DatabaseService.instance.getPrescriptions(selectedProfile!.id);
      reports = await DatabaseService.instance.getReports(selectedProfile!.id);
      medicines = await DatabaseService.instance.getMedicines(selectedProfile!.id);

      final scoreData = AiOcrService.instance.calculateEyeHealthScore(
        profile: selectedProfile!,
        prescriptions: prescriptions,
        medicines: medicines,
      );
      eyeHealthScore = scoreData['score'];
      scoreExplanation = scoreData['explanation'];

      doctorQuestions = AiOcrService.instance.generateDoctorQuestions(
        profile: selectedProfile!,
        prescriptions: prescriptions,
      );
    } else {
      prescriptions = [];
      reports = [];
      medicines = [];
      eyeHealthScore = 50;
      scoreExplanation = "No profile selected.";
      doctorQuestions = [];
    }

    setState(() => isLoading = false);
  }

  void _handleAddProfileRequested() async {
    bool canCreate = await EntitlementService.instance.canCreateProfile(currentUser);
    if (!canCreate) {
      _navigateToUpgrade();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnboardingScreen(
            user: currentUser,
            onProfileCreated: (newProfile) {
              Navigator.pop(context);
              setState(() => selectedProfile = newProfile);
              _refreshData();
            },
          ),
        ),
      );
    }
  }

  void _navigateToUploadPrescription() {
    if (selectedProfile == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionUploadScreen(
          user: currentUser,
          profile: selectedProfile!,
          onSaved: _refreshData,
        ),
      ),
    );
  }

  void _navigateToMedicineTracker() {
    if (selectedProfile == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineTrackerScreen(
          user: currentUser,
          profile: selectedProfile!,
          onUpdated: _refreshData,
        ),
      ),
    );
  }

  void _navigateToUpgrade() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PremiumUpgradeScreen(
          user: currentUser,
          onUpgraded: _refreshData,
        ),
      ),
    );
  }

  void _navigateToReportViewer() {
    if (selectedProfile == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportViewerScreen(
          user: currentUser,
          profile: selectedProfile!,
          prescriptions: prescriptions,
          reports: reports,
          medicines: medicines,
          eyeHealthScore: eyeHealthScore,
          scoreExplanation: scoreExplanation,
          doctorQuestions: doctorQuestions,
          onUpgradeRequested: _navigateToUpgrade,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentBottomNavIndex,
        onTap: (index) {
          setState(() => currentBottomNavIndex = index);
          if (index == 1) _navigateToMedicineTracker();
          if (index == 2) _navigateToReportViewer();
          if (index == 3) {
            if (selectedProfile != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileSettingsScreen(
                    user: currentUser,
                    profile: selectedProfile!,
                    onProfileDeleted: () {
                      selectedProfile = null;
                      _refreshData();
                    },
                    onLogout: widget.onLogout,
                  ),
                ),
              );
            }
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0284C7),
        unselectedItemColor: const Color(0xFF94A3B8),
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.droplet), label: "Drops & Meds"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.fileText), label: "PDF Report"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.settings), label: "Settings"),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card matching Reference Aesthetic
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFFE0F2FE),
                                child: const Icon(LucideIcons.userCheck, color: Color(0xFF0284C7), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Welcome, ${currentUser.name}",
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                  const Text("Good morning • Eye Care Active", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.bell, color: Color(0xFF475569)),
                                onPressed: () {},
                              ),
                              GestureDetector(
                                onTap: _navigateToUpgrade,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                  ),
                                  child: const Icon(LucideIcons.crown, size: 20, color: Color(0xFFD97706)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Profile Switcher Bar
                      ProfileSwitcherBar(
                        profiles: profiles,
                        selectedProfile: selectedProfile,
                        user: currentUser,
                        onSelectProfile: (prof) {
                          setState(() => selectedProfile = prof);
                          _refreshData();
                        },
                        onAddProfile: _handleAddProfileRequested,
                      ),
                      const SizedBox(height: 18),

                      if (selectedProfile != null) ...[
                        // Eye Health Score Card
                        EyeHealthScoreCard(
                          score: eyeHealthScore,
                          explanation: scoreExplanation,
                        ),
                        const SizedBox(height: 16),

                        // B&W Academic Engineering Grid Technical Chart
                        AcademicBwChart(prescriptions: prescriptions),
                        const SizedBox(height: 16),

                        // AI Doctor Questions Card
                        AiDoctorQuestionsCard(questions: doctorQuestions),
                        const SizedBox(height: 16),

                        // Quick Actions Grid
                        const Text("Quick Eye-Care Actions", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionTile(
                                icon: LucideIcons.camera,
                                label: "Add Prescription",
                                subtitle: "Manual / Gemini OCR",
                                color: const Color(0xFF0284C7),
                                onTap: _navigateToUploadPrescription,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildActionTile(
                                icon: LucideIcons.droplets,
                                label: "Log Eye Drops",
                                subtitle: "Reminders & Audio",
                                color: const Color(0xFF10B981),
                                onTap: _navigateToMedicineTracker,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionTile(
                                icon: LucideIcons.fileSpreadsheet,
                                label: "PDF Summary",
                                subtitle: "Multilingual Report",
                                color: const Color(0xFF8B5CF6),
                                onTap: _navigateToReportViewer,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildActionTile(
                                icon: LucideIcons.crown,
                                label: "Specz Plus",
                                subtitle: "Up to 5 Profiles",
                                color: const Color(0xFFD97706),
                                onTap: _navigateToUpgrade,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Current Prescription Summary Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Current Eye Specs Record", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                  Icon(LucideIcons.glasses, size: 20, color: Color(0xFF0284C7)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (prescriptions.isNotEmpty) ...[
                                Builder(
                                  builder: (context) {
                                    final latest = prescriptions.first;
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text("Right Eye (OD)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                                    const SizedBox(height: 2),
                                                    Text("SPH: ${latest.rightSph ?? '-'} | CYL: ${latest.rightCyl ?? '-'}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                                    Text("Axis: ${latest.rightAxis ?? '-'}°", style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text("Left Eye (OS)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                                    const SizedBox(height: 2),
                                                    Text("SPH: ${latest.leftSph ?? '-'} | CYL: ${latest.leftCyl ?? '-'}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                                    Text("Axis: ${latest.leftAxis ?? '-'}°", style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text("Doctor: ${latest.doctorName} • Clinic: ${latest.clinicName}", style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                      ],
                                    );
                                  },
                                ),
                              ] else ...[

                                const Text("No prescription logged yet. Tap 'Add Prescription' above.", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        const MedicalDisclaimerBanner(),
                        const SizedBox(height: 24),
                      ] else ...[
                        const Center(
                          child: Text("No active profile. Tap '+ Add Profile' above to start!"),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }


  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
