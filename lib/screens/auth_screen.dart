import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/app_icons.dart';
import '../utils/app_theme.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class AuthScreen extends StatefulWidget {
  final Function(UserModel) onLoginSuccess;
  const AuthScreen({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController(text: "karthik@specz.co");
  final _passwordController = TextEditingController(text: "password123");
  final _nameController = TextEditingController(text: "Karthik");
  bool isSignUp = false;
  bool isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(_fadeAnim);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final user = UserModel(
      id: 'user_default',
      email: _emailController.text.trim(),
      name: isSignUp ? _nameController.text.trim() : 'Karthik',
      plan: 'free',
      status: 'free',
      createdAt: DateTime.now().toIso8601String(),
    );

    await DatabaseService.instance.database; // Ensure DB init
    setState(() => isLoading = false);
    widget.onLoginSuccess(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: AnimatedBuilder(
                animation: _fadeAnim,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnim.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnim.value),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Animated Eye Logo
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryLight.withOpacity(0.3),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.visibility_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // App Name
                    const Text(
                      "SPECZ.CO",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSignUp ? "Create Your Account" : "Welcome Back!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Digital Eye-Care Companion for Families",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Glass Form Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (isSignUp) ...[
                            TextField(
                              controller: _nameController,
                              decoration: AppTheme.inputDecoration(
                                label: "Full Name",
                                prefixIcon: LucideIcons.user,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: AppTheme.inputDecoration(
                              label: "Email Address",
                              prefixIcon: LucideIcons.mail,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: AppTheme.inputDecoration(
                              label: "Password",
                              prefixIcon: LucideIcons.lock,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: AppTheme.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Gradient Sign In Button
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
                                onPressed: isLoading ? null : _handleAuth,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                      )
                                    : Text(
                                        isSignUp ? "Sign Up" : "Sign In",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: AppTheme.border)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  "Or sign in with",
                                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ),
                              Expanded(child: Divider(color: AppTheme.border)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Google Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _handleAuth,
                              icon: const Text("G", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF4285F4))),
                              label: const Text(
                                "Sign in with Google",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppTheme.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                ),
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Toggle Sign Up / Sign In
                          GestureDetector(
                            onTap: () => setState(() => isSignUp = !isSignUp),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                children: [
                                  TextSpan(
                                    text: isSignUp ? "Already have an account? " : "Don't have an account? ",
                                  ),
                                  TextSpan(
                                    text: isSignUp ? "Sign In" : "Sign Up",
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
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
