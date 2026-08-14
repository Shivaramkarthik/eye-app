import 'dart:async';
import '../models/user_model.dart';
import '../data/remote/api_client.dart';
import 'database_service.dart';

class RazorpayService {
  static final RazorpayService instance = RazorpayService._internal();
  RazorpayService._internal();

  /// Enforces server-backed Razorpay payment flow.
  /// Order creation occurs on backend server (POST /subscriptions/order)
  /// and signature verification occurs via backend API (POST /subscriptions/verify).
  Future<bool> processSubscriptionPayment({
    required UserModel user,
    required String planId,
    String? backendOrderId,
    String? backendPaymentId,
    String? backendSignature,
  }) async {
    if (user.id.isEmpty) return false;

    try {
      final response = await ApiClient.instance.post(
        '/subscriptions/verify',
        data: {
          'user_id': user.id,
          'plan_id': planId,
          'razorpay_order_id': backendOrderId,
          'razorpay_payment_id': backendPaymentId,
          'razorpay_signature': backendSignature,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final subId = response.data['subscription_id'] ?? "sub_rzp_${DateTime.now().millisecondsSinceEpoch}";
        final renewalDate = response.data['expires_at'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String();

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
