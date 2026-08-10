import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../remote/subscription_api.dart';

class SubscriptionRepository {
  final SubscriptionApi _remoteApi = SubscriptionApi();

  Future<Map<String, dynamic>> createOrder({String plan = "plus"}) async {
    return await _remoteApi.createOrder(plan: plan);
  }

  Future<void> verifyPaymentAndUpgrade({
    required UserModel user,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    // 1. Verify Payment on FastAPI Backend Server (HMAC Signature Check)
    final result = await _remoteApi.verifyPayment(
      orderId: orderId,
      paymentId: paymentId,
      signature: signature,
      plan: "plus",
    );

    // 2. Update Local SQLite database user plan
    final plan = result['plan'] ?? 'plus';
    final status = result['status'] ?? 'ACTIVE';
    final subId = result['id'];
    final expiresAt = result['expires_at'];

    await DatabaseService.instance.updateUserPlan(
      user.id,
      plan,
      status,
      subId,
      expiresAt,
    );
  }

  Future<Map<String, dynamic>> getAuthoritativeEntitlements() async {
    try {
      return await _remoteApi.getEntitlements();
    } catch (_) {
      // Local fallback
      return {
        'plan': 'free',
        'status': 'ACTIVE',
        'max_profiles': 1,
        'features': {'ai_summary': false, 'cloud_reports': true},
      };
    }
  }
}
