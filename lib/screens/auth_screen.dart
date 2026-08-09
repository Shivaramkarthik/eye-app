import 'package:flutter/material.dart';
import '../utils/app_icons.dart';


import '../models/user_model.dart';
import '../services/database_service.dart';

class AuthScreen extends StatefulWidget {
  final Function(UserModel) onLoginSuccess;
  const AuthScreen({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController(text: "karthik@specz.co");
  final _passwordController = TextEditingController(text: "password123");
  final _nameController = TextEditingController(text: "Karthik");
  bool isSignUp = false;
  bool isLoading = false;

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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.eye, size: 44, color: Color(0xFF0284C7)),
                ),
                const SizedBox(height: 16),
                const Text(
                  "SPECZ.CO",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Digital Eye-Care Companion for Families",
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        isSignUp ? "Create Your Account" : "Sign In to Your Records",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 20),
                      if (isSignUp) ...[
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: "Full Name",
                            prefixIcon: Icon(LucideIcons.user, size: 18),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "Email Address",
                          prefixIcon: Icon(LucideIcons.mail, size: 18),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(LucideIcons.lock, size: 18),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(isSignUp ? "Sign Up" : "Sign In", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => setState(() => isSignUp = !isSignUp),
                        child: Text(
                          isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up",
                          style: const TextStyle(color: Color(0xFF0284C7)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
