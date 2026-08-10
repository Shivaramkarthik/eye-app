class SubscriptionModel {
  final String id;
  final String userId;
  final String provider; // 'razorpay'
  final String? providerCustomerId;
  final String? providerOrderId;
  final String? providerPaymentId;
  final String? providerSubscriptionId;
  final String plan; // 'free', 'plus'
  final String status; // 'PENDING', 'ACTIVE', 'CANCELLED', 'EXPIRED', 'PAYMENT_FAILED', 'PAUSED'
  final String startedAt;
  final String? expiresAt;
  final String createdAt;
  final String updatedAt;

  SubscriptionModel({
    required this.id,
    required this.userId,
    this.provider = 'razorpay',
    this.providerCustomerId,
    this.providerOrderId,
    this.providerPaymentId,
    this.providerSubscriptionId,
    required this.plan,
    required this.status,
    required this.startedAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'provider': provider,
      'provider_customer_id': providerCustomerId,
      'provider_order_id': providerOrderId,
      'provider_payment_id': providerPaymentId,
      'provider_subscription_id': providerSubscriptionId,
      'plan': plan,
      'status': status,
      'started_at': startedAt,
      'expires_at': expiresAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? map['userId'] ?? '',
      provider: map['provider'] ?? 'razorpay',
      providerCustomerId: map['provider_customer_id'] ?? map['providerCustomerId'],
      providerOrderId: map['provider_order_id'] ?? map['providerOrderId'],
      providerPaymentId: map['provider_payment_id'] ?? map['providerPaymentId'],
      providerSubscriptionId: map['provider_subscription_id'] ?? map['providerSubscriptionId'],
      plan: map['plan'] ?? 'free',
      status: map['status'] ?? 'ACTIVE',
      startedAt: map['started_at'] ?? map['startedAt'] ?? DateTime.now().toIso8601String(),
      expiresAt: map['expires_at'] ?? map['expiresAt'],
      createdAt: map['created_at'] ?? map['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at'] ?? map['updatedAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
