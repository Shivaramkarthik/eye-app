import 'api_client.dart';

class SubscriptionApi {
  final ApiClient _client = ApiClient.instance;

  Future<Map<String, dynamic>> createOrder({String plan = "plus"}) async {
    final res = await _client.post('/subscriptions/create-order', data: {'plan': plan});
    return res.data;
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    String plan = "plus",
  }) async {
    final res = await _client.post('/subscriptions/verify-payment', data: {
      'razorpay_order_id': orderId,
      'razorpay_payment_id': paymentId,
      'razorpay_signature': signature,
      'plan': plan,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getEntitlements() async {
    final res = await _client.get('/subscriptions/entitlements/me');
    return res.data;
  }
}
