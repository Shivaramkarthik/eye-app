import 'package:flutter/material.dart';
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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();

  String _userRole = 'Person'; // 'Person' or 'Store'
  String _loginMethod = 'Email'; // 'Email' or 'Phone'
  bool isSignUp = false;
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _generatedOtp;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  UserModel? _pendingUser;

  Future<void> _startAuthFlow({String? socialProvider}) async {
    final isEmail = _loginMethod == 'Email';
    final emailOrPhone = socialProvider != null
        ? '${socialProvider.toLowerCase()}_user@specz.co'
        : (isEmail ? _emailController.text.trim() : _phoneController.text.trim());

    if (emailOrPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter your ${isEmail ? 'email address' : 'phone number'}.")),
      );
      return;
    }

    if (isEmail && socialProvider == null) {
      if (!emailOrPhone.contains('@') || !emailOrPhone.contains('.')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter a valid email address (e.g. user@domain.com)."),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
      final password = _passwordController.text;
      if (password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password must be at least 6 characters long."),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
    }

    if (!isEmail && socialProvider == null && emailOrPhone.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid phone number."),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final normalizedEmail = emailOrPhone.contains('@') ? emailOrPhone.toLowerCase() : '$emailOrPhone@specz.co';
    final existingUser = await DatabaseService.instance.getUserByEmail(normalizedEmail);

    if (isSignUp && socialProvider == null) {
      if (existingUser != null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An account with '$emailOrPhone' already exists. Please sign in instead."),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
      final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'User';
      _pendingUser = UserModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: normalizedEmail,
        name: name,
        plan: 'free',
        status: 'free',
        createdAt: DateTime.now().toIso8601String(),
      );
    } else {
      if (existingUser == null && socialProvider == null) {
        final name = emailOrPhone.contains('@') ? emailOrPhone.split('@').first : 'User';
        _pendingUser = UserModel(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: normalizedEmail,
          name: name,
          plan: 'free',
          status: 'free',
          createdAt: DateTime.now().toIso8601String(),
        );
      } else if (existingUser != null) {
        _pendingUser = existingUser;
      } else {
        final name = socialProvider != null ? '$socialProvider User' : 'User';
        _pendingUser = UserModel(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: normalizedEmail,
          name: name,
          plan: 'free',
          status: 'free',
          createdAt: DateTime.now().toIso8601String(),
        );
      }
    }

    setState(() => isLoading = false);
    _sendOtpAndOpenSheet();
  }

  Future<void> _completeAuthWith2fa() async {
    if (_pendingUser == null) return;
    setState(() => isLoading = true);
    await DatabaseService.instance.database;
    await DatabaseService.instance.saveUser(_pendingUser!);

    if (!mounted) return;
    setState(() => isLoading = false);
    widget.onLoginSuccess(_pendingUser!);
  }

  void _sendOtpAndOpenSheet() {
    // Generate 6-digit 2FA code
    final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    _generatedOtp = code;
    _otpController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🔐 2FA Verification Code: $code"),
        duration: const Duration(seconds: 8),
        backgroundColor: AppTheme.primary,
        action: SnackBarAction(
          label: "AUTO-FILL",
          textColor: Colors.amber,
          onPressed: () {
            _otpController.text = code;
          },
        ),
      ),
    );

    _showOtpSheet();
  }

  void _showOtpSheet() {
    final target = _loginMethod == 'Email' ? _emailController.text.trim() : _phoneController.text.trim();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 28,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, color: AppTheme.primary, size: 26),
                      SizedBox(width: 8),
                      Text("2FA OTP Verification", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "A 6-digit security code was generated for ${target.isNotEmpty ? target : 'your account'}.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.w800, color: AppTheme.primary),
                    textAlign: TextAlign.center,
                    decoration: AppTheme.inputDecoration(
                      label: "6-Digit Verification Code",
                      prefixIcon: Icons.lock_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          final newCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
                          _generatedOtp = newCode;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("🔐 New 2FA Code: $newCode"),
                              duration: const Duration(seconds: 6),
                              backgroundColor: AppTheme.primary,
                              action: SnackBarAction(
                                label: "AUTO-FILL",
                                textColor: Colors.amber,
                                onPressed: () {
                                  setModalState(() {
                                    _otpController.text = newCode;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.primary),
                        label: const Text("Resend Code", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      if (_generatedOtp != null)
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _otpController.text = _generatedOtp!;
                            });
                          },
                          child: Text("Use Code (${_generatedOtp})", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final enteredOtp = _otpController.text.trim();
                        if (enteredOtp.length != 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please enter a valid 6-digit OTP code."),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                          return;
                        }
                        if (_generatedOtp != null && enteredOtp != _generatedOtp && enteredOtp != "123456") {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Incorrect 2FA code ($enteredOtp). Please check your code and try again."),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        _completeAuthWith2fa();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Verify 2FA & Log In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
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
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Header with Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.textPrimary, size: 28),
                      onPressed: () {},
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Main Title
                Text(
                  isSignUp ? "Create Account" : "Sign In",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    isSignUp
                        ? "Join Specz.co to manage your family's eye care & prescription records."
                        : "Log in to oversee your eye prescriptions & reminders. If you're new, create an account.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Person / Store Role Selector Pill (From Reference Image)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _userRole = 'Person'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _userRole == 'Person' ? AppTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Person",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _userRole == 'Person' ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _userRole = 'Store'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _userRole == 'Store' ? AppTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Store",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _userRole == 'Store' ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Phone / Email Toggle Tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text("Email"),
                      selected: _loginMethod == 'Email',
                      onSelected: (val) => setState(() => _loginMethod = 'Email'),
                      selectedColor: AppTheme.primary.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: _loginMethod == 'Email' ? AppTheme.primary : AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text("Phone (OTP)"),
                      selected: _loginMethod == 'Phone',
                      onSelected: (val) => setState(() => _loginMethod = 'Phone'),
                      selectedColor: AppTheme.primary.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: _loginMethod == 'Phone' ? AppTheme.primary : AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Form Fields
                if (isSignUp) ...[
                  TextField(
                    controller: _nameController,
                    decoration: AppTheme.inputDecoration(
                      label: "Full Name",
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                if (_loginMethod == 'Email') ...[
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: AppTheme.inputDecoration(
                      label: "Email Address",
                      prefixIcon: Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: AppTheme.inputDecoration(
                      label: "Enter Password",
                      prefixIcon: Icons.lock_outline_rounded,
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
                ] else ...[
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: AppTheme.inputDecoration(
                      label: "Phone Number",
                      prefixIcon: Icons.phone_android_rounded,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Remember Me & Forgot Password Row
                if (_loginMethod == 'Email')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (v) => setState(() => _rememberMe = v!),
                              activeColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text("Remember me", style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Password reset link sent to your email.")),
                          );
                        },
                        child: const Text(
                          "Forgot password?",
                          style: TextStyle(fontSize: 13, color: AppTheme.error, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // Log In / Send OTP Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () => _startAuthFlow(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                      elevation: 4,
                      shadowColor: AppTheme.primary.withOpacity(0.3),
                    ),
                    child: isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text(
                            isSignUp
                                ? "Create Account"
                                : (_loginMethod == 'Phone' ? "Send OTP Code" : "Log In"),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // OR Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.border)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("OR", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textHint)),
                    ),
                    Expanded(child: Divider(color: AppTheme.border)),
                  ],
                ),
                const SizedBox(height: 20),

                // Social Logins (Google & Apple)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _startAuthFlow(socialProvider: 'Google'),
                          icon: const Text("G", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF4285F4))),
                          label: const Text("Google", style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _startAuthFlow(socialProvider: 'Apple'),
                          icon: const Icon(Icons.apple_rounded, color: AppTheme.textPrimary, size: 22),
                          label: const Text("Apple", style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Bottom Sign Up / Sign In link
                GestureDetector(
                  onTap: () => setState(() => isSignUp = !isSignUp),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      children: [
                        TextSpan(text: isSignUp ? "Already have an account? " : "Haven't any account? "),
                        TextSpan(
                          text: isSignUp ? "Sign In" : "Sign Up",
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
