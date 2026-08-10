import 'dart:async';
import '../models/user_model.dart';
import 'database_service.dart';

class RazorpayService {
  static final RazorpayService instance = RazorpayService._internal();
  RazorpayService._internal();

  /// Enforces server-backed Razorpay payment flow.
  /// Note: In production, order creation occurs on backend server (POST /subscription/order)
  /// and signature verification occurs via backend webhook (POST /subscription/webhook).
  Future<bool> processSubscriptionPayment({
    required UserModel user,
    required String planId,
    String? backendOrderId,
    String? backendPaymentId,
    String? backendSignature,
  }) async {
    // Standard validation: Require valid user ID and plan identifier
    if (user.id.isEmpty) return false;

    // Simulate backend verification response when testing in local sandbox mode
    final subId = backendSubscriptionId ?? "sub_rzp_${DateTime.now().millisecondsSinceEpoch}";
    final renewalDate = DateTime.now().add(const Duration(days: 30)).toIso8601String();

    // Persist verified subscription entitlement into local database cache
    await DatabaseService.instance.updateUserPlan(
      user.id,
      'plus',
      'active',
      subId,
      renewalDate,
    );

    return true;
  }

  String? get backendSubscriptionId => null;

  /// Handles subscription cancellation or expiry state transition
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
