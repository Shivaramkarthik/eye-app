import 'package:flutter/material.dart';
import '../utils/app_icons.dart';


import '../models/user_model.dart';
import '../services/razorpay_service.dart';

class PremiumUpgradeScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback onUpgraded;

  const PremiumUpgradeScreen({
    Key? key,
    required this.user,
    required this.onUpgraded,
  }) : super(key: key);

  @override
  State<PremiumUpgradeScreen> createState() => _PremiumUpgradeScreenState();
}

class _PremiumUpgradeScreenState extends State<PremiumUpgradeScreen> {
  bool isProcessing = false;

  Future<void> _handleRazorpayCheckout() async {
    setState(() => isProcessing = true);

    bool success = await RazorpayService.instance.processSubscriptionPayment(
      user: widget.user,
      planId: 'specz_plus_99',
    );

    if (!mounted) return;
    setState(() => isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment Successful! Welcome to Specz Plus 🎉")),
      );
      widget.onUpgraded();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Upgrade to Specz Plus", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
                child: const Icon(LucideIcons.crown, size: 48, color: Color(0xFFD97706)),
              ),
              const SizedBox(height: 16),
              const Text("Specz Plus Plan", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              const Text("Manage your entire family's vision health in one place", style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              const SizedBox(height: 24),

              // Pricing Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [

                        Text("₹99", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text(" / month", style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    _buildFeatureRow("Manage up to 5 family active profiles"),
                    _buildFeatureRow("Multilingual downloadable PDF summary reports"),
                    _buildFeatureRow("AI Eye Health Index & Doctor Visit Questions"),
                    _buildFeatureRow("Unlimited eye drop & medicine reminders"),
                    _buildFeatureRow("Academic Black & White Refraction Trend Charts"),
                    _buildFeatureRow("Priority Support & Cloud Backup"),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: isProcessing ? null : _handleRazorpayCheckout,
                        icon: const Icon(LucideIcons.creditCard, color: Colors.white),
                        label: isProcessing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Pay ₹99 with Razorpay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text("Cancel anytime from account settings. Secure Razorpay payment processing.", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(LucideIcons.checkCircle2, size: 18, color: Color(0xFF10B981)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
        ],
      ),
    );
  }
}
