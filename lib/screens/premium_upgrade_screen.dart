import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../models/user_model.dart';
import '../services/razorpay_service.dart';

class PremiumUpgradeScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback onUpgraded;

  const PremiumUpgradeScreen({
    super.key,
    required this.user,
    required this.onUpgraded,
  });

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
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text("Upgrade to Specz Plus"),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Hero Banner with Warm Gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.warmGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  boxShadow: AppTheme.accentShadow,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Specz Plus Plan",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Manage your entire family's vision health in one app",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Features & Price Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: const [
                        Text("₹99", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                        Text(" / month", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),

                    _buildFeatureRow("Manage up to 5 family active profiles"),
                    _buildFeatureRow("Multilingual downloadable PDF summary reports"),
                    _buildFeatureRow("AI Eye Health Index & Doctor Visit Questions"),
                    _buildFeatureRow("Unlimited eye drop & medicine reminders"),
                    _buildFeatureRow("Academic Black & White Refraction Trend Charts"),
                    _buildFeatureRow("Priority Support & Cloud Backup"),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          boxShadow: AppTheme.primaryShadow,
                        ),
                        child: ElevatedButton.icon(
                          onPressed: isProcessing ? null : _handleRazorpayCheckout,
                          icon: const Icon(Icons.credit_card_rounded, color: Colors.white),
                          label: isProcessing
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text("Pay ₹99 with Razorpay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text("Cancel anytime from account settings. Secure Razorpay payment gateway.", style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 16, color: AppTheme.success),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary))),
        ],
      ),
    );
  }
}
