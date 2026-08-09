import 'dart:async';
import '../models/user_model.dart';
import 'database_service.dart';

class RazorpayService {
  static final RazorpayService instance = RazorpayService._internal();
  RazorpayService._internal();

  /// Simulates Razorpay ₹99/month Specz Plus checkout workflow
  Future<bool> processSubscriptionPayment({
    required UserModel user,
    required String planId, // 'specz_plus_99'
  }) async {
    // Simulated Razorpay API Gateway response delay
    await Future.delayed(const Duration(milliseconds: 1200));

    final subId = "sub_rzp_${DateTime.now().millisecondsSinceEpoch}";
    final renewalDate = DateTime.now().add(const Duration(days: 30)).toIso8601String();

    // Server-side entitlement update
    await DatabaseService.instance.updateUserPlan(
      user.id,
      'plus',
      'active',
      subId,
      renewalDate,
    );

    return true;
  }

  /// Simulates subscription cancellation or expiry
  Future<void> expireSubscription(UserModel user) async {
    await DatabaseService.instance.updateUserPlan(
      user.id,
      'plus',
      'expired',
      user.subscriptionId,
      user.nextRenewalDate,
    );
  }
}
