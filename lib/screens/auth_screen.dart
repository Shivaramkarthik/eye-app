import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class AuthScreen extends StatefulWidget {
  final Function(UserModel) onLoginSuccess;
  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool isLoading = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _fadeController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _signInLocally() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name to continue.')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await DatabaseService.instance.database;

      // Build a local guest user — no backend needed
      final user = UserModel(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        email: _emailController.text.trim().isEmpty
            ? '${name.toLowerCase().replaceAll(' ', '.')}@local.specz'
            : _emailController.text.trim(),
        name: name,
        avatarUrl: null,
        plan: 'free',
        status: 'free',
        createdAt: DateTime.now().toIso8601String(),
      );

      await DatabaseService.instance.saveUser(user);

      if (!mounted) return;
      widget.onLoginSuccess(user);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SizedBox(
              height: screenHeight -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // App Icon / Branding
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.visibility_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // App Name
                    const Text(
                      "Specz.co",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 8),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Your family's digital eye-care companion.\nPrescriptions • Reminders • Reports",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Dev notice banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: AppTheme.warning, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Testing mode — Google Sign-In temporarily disabled.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name field
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: AppTheme.inputDecoration(
                        label: 'Your Name',
                        prefixIcon: Icons.person_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Email field (optional)
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: AppTheme.inputDecoration(
                        label: 'Email (optional)',
                        prefixIcon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Enter App button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.primaryShadow,
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _signInLocally,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_forward_rounded, color: Colors.white),
                                    SizedBox(width: 10),
                                    Text(
                                      'Enter App',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 1),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        "Testing build — all data stored locally on device.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textHint,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
