import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
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
import 'ai_chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback onLogout;

  const DashboardScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
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

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _refreshData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (profiles.isEmpty) {
      setState(() => isLoading = true);
    }
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

    if (!mounted) return;
    setState(() => isLoading = false);
    _fadeController.forward(from: 0);
  }

  void _handleAddProfileRequested() async {
    bool canCreate = await EntitlementService.instance.canCreateProfile(currentUser);
    if (!mounted) return;
    if (!canCreate) {
      _navigateToUpgrade();
    } else {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          OnboardingScreen(
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
      AppTheme.fadeSlideRoute(
        PrescriptionUploadScreen(
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
      AppTheme.fadeSlideRoute(
        MedicineTrackerScreen(
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
      AppTheme.fadeSlideRoute(
        PremiumUpgradeScreen(
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
      AppTheme.fadeSlideRoute(
        ReportViewerScreen(
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

  void _navigateToAiChat([String? question]) {
    Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        AiChatScreen(
          user: currentUser,
          profile: selectedProfile,
          initialQuestion: question,
        ),
      ),
    );
  }

  void _handleScoreCardTap() {
    if (selectedProfile == null) return;
    if (prescriptions.isEmpty) {
      _navigateToUploadPrescription();
    } else {
      _showEyeHealthScoreBreakdownModal();
    }
  }

  void _showEyeHealthScoreBreakdownModal() {
    final latestPrescription = prescriptions.first;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
          ),
          padding: const EdgeInsets.all(24),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Eye Health Score Analysis",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Based on ${selectedProfile?.name}'s prescription",
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "$eyeHealthScore / 100",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 14),

                // Latest Prescription Details Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.medical_information_rounded, size: 16, color: AppTheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                "Logged Prescription (${latestPrescription.prescriptionDate})",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                          const Icon(Icons.verified_rounded, size: 16, color: AppTheme.success),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Doctor: ${latestPrescription.doctorName} · ${latestPrescription.clinicName}",
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Right Eye (OD)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                  const SizedBox(height: 2),
                                  Text("SPH: ${latestPrescription.rightSph}D\nCYL: ${latestPrescription.rightCyl}D", style: const TextStyle(fontSize: 12, height: 1.3)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Left Eye (OS)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                  const SizedBox(height: 2),
                                  Text("SPH: ${latestPrescription.leftSph}D\nCYL: ${latestPrescription.leftCyl}D", style: const TextStyle(fontSize: 12, height: 1.3)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text("Score Calculation Breakdown", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 10),
                _buildScoreFactorRow(
                  icon: Icons.assignment_turned_in_rounded,
                  title: "Prescription Logged",
                  pts: "+35 Pts",
                  desc: "Valid doctor prescription scan on record.",
                  color: AppTheme.success,
                ),
                const SizedBox(height: 10),
                _buildScoreFactorRow(
                  icon: Icons.balance_rounded,
                  title: "Refractive Power Evaluation",
                  pts: "+35 Pts",
                  desc: "SPH/CYL focal power stability analysis.",
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 10),
                _buildScoreFactorRow(
                  icon: Icons.water_drop_rounded,
                  title: "Eye Drop Adherence",
                  pts: "+30 Pts",
                  desc: medicines.isNotEmpty ? "${medicines.length} Eye drop schedule(s) active" : "No eye drops configured",
                  color: AppTheme.warning,
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          scoreExplanation,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _navigateToUploadPrescription();
                    },
                    icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                    label: const Text("Update / Scan New Prescription", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreFactorRow({
    required IconData icon,
    required String title,
    required String pts,
    required String desc,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Text(pts, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, "Home"),
                _buildNavItem(1, Icons.water_drop_rounded, "Drops"),
                _buildNavItem(2, Icons.description_rounded, "Reports"),
                _buildNavItem(3, Icons.settings_rounded, "Settings"),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Loading your eye care data...",
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : FadeTransition(
                opacity: _fadeAnim,
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  color: AppTheme.primary,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Header
                        _buildWelcomeHeader(),
                        const SizedBox(height: 20),

                        // Profile Switcher
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
                        const SizedBox(height: 20),

                        if (selectedProfile != null) ...[
                          // Eye Health Score
                          EyeHealthScoreCard(
                            score: eyeHealthScore,
                            explanation: scoreExplanation,
                            onTap: _handleScoreCardTap,
                          ),
                          const SizedBox(height: 20),

                          // Quick Actions
                          const Text(
                            "Quick Actions",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildQuickActionsGrid(),
                          const SizedBox(height: 20),

                          // Current Prescription Card
                          _buildPrescriptionCard(),
                          const SizedBox(height: 20),

                          // Chart
                          AcademicBwChart(prescriptions: prescriptions),
                          const SizedBox(height: 20),

                          // AI Doctor Questions
                          AiDoctorQuestionsCard(
                            questions: doctorQuestions,
                            onQuestionTap: (question) => _navigateToAiChat(question),
                          ),
                          const SizedBox(height: 20),

                          const MedicalDisclaimerBanner(),
                          const SizedBox(height: 24),
                        ] else ...[
                          const SizedBox(height: 60),
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person_add_rounded,
                                    size: 48,
                                    color: AppTheme.primary.withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "No active profile",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Tap '+ Add Profile' above to get started!",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = currentBottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => currentBottomNavIndex = index);
        if (index == 1) _navigateToMedicineTracker();
        if (index == 2) _navigateToReportViewer();
        if (index == 3) {
          if (selectedProfile != null) {
            Navigator.push(
              context,
              AppTheme.fadeSlideRoute(
                ProfileSettingsScreen(
                  user: currentUser,
                  profile: selectedProfile!,
                  onProfileDeleted: () {
                    selectedProfile = null;
                    _refreshData();
                  },
                  onProfileUpdated: (updated) {
                    _refreshData();
                  },
                  onLogout: widget.onLogout,
                ),
              ),
            );
          }
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppTheme.primary : AppTheme.textHint,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primary : AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfileSettings() {
    if (selectedProfile != null) {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          ProfileSettingsScreen(
            user: currentUser,
            profile: selectedProfile!,
            onProfileDeleted: () {
              selectedProfile = null;
              _refreshData();
            },
            onLogout: widget.onLogout,
            onProfileUpdated: (updatedProf) {
              setState(() {
                selectedProfile = updatedProf;
              });
              _refreshData();
            },
          ),
        ),
      );
    }
  }

  Widget _buildWelcomeHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _navigateToProfileSettings,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.primaryShadow,
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome, ${currentUser.name}",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              "${_getGreeting()} · Profile Settings",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded, color: AppTheme.textSecondary, size: 22),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _navigateToUpgrade,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.warmGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.accentShadow,
                ),
                child: const Icon(Icons.workspace_premium_rounded, size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.camera_alt_rounded,
                label: "Add Prescription",
                subtitle: "Manual / Gemini OCR",
                gradient: AppTheme.primaryGradient,
                onTap: _navigateToUploadPrescription,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.water_drop_rounded,
                label: "Log Eye Drops",
                subtitle: "Reminders & Audio",
                gradient: AppTheme.successGradient,
                onTap: _navigateToMedicineTracker,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.description_rounded,
                label: "PDF Summary",
                subtitle: "Multilingual Report",
                gradient: AppTheme.purpleGradient,
                onTap: _navigateToReportViewer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.workspace_premium_rounded,
                label: "Specz Plus",
                subtitle: "Up to 5 Profiles",
                gradient: AppTheme.warmGradient,
                onTap: _navigateToUpgrade,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.auto_awesome_rounded,
          label: "Chat with Specz AI Assistant",
          subtitle: "Ask about SPH/CYL, drop schedules & eye health tips",
          gradient: AppTheme.primaryGradient,
          onTap: _navigateToAiChat,
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.remove_red_eye_rounded, size: 18, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Current Eye Specs",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Latest",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (prescriptions.isNotEmpty) ...[
            Builder(
              builder: (context) {
                final latest = prescriptions.first;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildEyeDataBox("Right Eye (OD)", latest.rightSph, latest.rightCyl, latest.rightAxis, AppTheme.primary)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildEyeDataBox("Left Eye (OS)", latest.leftSph, latest.leftCyl, latest.leftAxis, AppTheme.accent)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.medical_services_rounded, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Dr. ${latest.doctorName} · ${latest.clinicName}",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.add_circle_outline_rounded, size: 20, color: AppTheme.textHint),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "No prescription logged yet. Tap 'Add Prescription' above.",
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEyeDataBox(String label, double? sph, double? cyl, int? axis, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accentColor,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "SPH: ${sph ?? '-'}  CYL: ${cyl ?? '-'}",
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Axis: ${axis ?? '-'}°",
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
