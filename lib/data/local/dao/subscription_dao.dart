import 'package:sqflite/sqflite.dart';
import '../../../models/subscription_model.dart';

class SubscriptionDao {
  final Database db;
  SubscriptionDao(this.db);

  Future<SubscriptionModel?> getActiveSubscription(String userId) async {
    final res = await db.query(
      'subscriptions',
      where: 'user_id = ? AND status = ?',
      orderBy: 'created_at DESC',
      limit: 1,
      whereArgs: [userId, 'ACTIVE'],
    );
    if (res.isNotEmpty) {
      return SubscriptionModel.fromMap(res.first);
    }
    return null;
  }

  Future<void> insertSubscription(SubscriptionModel sub) async {
    await db.insert('subscriptions', sub.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
