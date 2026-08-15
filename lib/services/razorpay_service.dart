import 'dart:async';
import '../models/user_model.dart';
import '../data/remote/subscription_api.dart';
import 'database_service.dart';

class RazorpayService {
  static final RazorpayService instance = RazorpayService._internal();
  RazorpayService._internal();

  final SubscriptionApi _subscriptionApi = SubscriptionApi();

  /// Enforces server-backed Razorpay payment flow.
  /// Order creation occurs on backend server (POST /subscriptions/create-order)
  /// and signature verification occurs via backend API (POST /subscriptions/verify-payment).
  Future<bool> processSubscriptionPayment({
    required UserModel user,
    required String planId,
    String? backendOrderId,
    String? backendPaymentId,
    String? backendSignature,
  }) async {
    if (user.id.isEmpty) return false;

    try {
      if (backendOrderId != null && backendPaymentId != null && backendSignature != null) {
        final data = await _subscriptionApi.verifyPayment(
          orderId: backendOrderId,
          paymentId: backendPaymentId,
          signature: backendSignature,
          plan: planId,
        );

        final subId = data['subscription_id'] ?? data['id'] ?? "sub_rzp_${DateTime.now().millisecondsSinceEpoch}";
        final renewalDate = data['expires_at'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String();

        await DatabaseService.instance.updateUserPlan(
          user.id,
          'plus',
          'active',
          subId,
          renewalDate,
        );
        return true;
      }
    } catch (_) {
      return false;
    }

    return false;
  }

  /// Handles subscription cancellation or expiry state transition
  Future<void> expireSubscription(UserModel user) async {
    await DatabaseService.instance.updateUserPlan(
      user.id,
      'free',
      'expired',
      null,
      null,
    );
  }
}
