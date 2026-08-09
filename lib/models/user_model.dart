class UserModel {
  final String id;
  final String email;
  final String name;
  final String plan; // 'free' | 'plus'
  final String? subscriptionId;
  final String status; // 'free' | 'active' | 'expired' | 'cancelled'
  final String? nextRenewalDate;
  final String createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.plan = 'free',
    this.subscriptionId,
    this.status = 'free',
    this.nextRenewalDate,
    required this.createdAt,
  });

  bool get isPlusActive => plan == 'plus' && status == 'active';
  int get maxProfiles => isPlusActive ? 5 : 1;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'plan': plan,
      'subscriptionId': subscriptionId,
      'status': status,
      'nextRenewalDate': nextRenewalDate,
      'createdAt': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? 'Karthik',
      plan: map['plan'] ?? 'free',
      subscriptionId: map['subscriptionId'],
      status: map['status'] ?? 'free',
      nextRenewalDate: map['nextRenewalDate'],
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
