import 'package:sqflite/sqflite.dart';
import '../../../models/user_model.dart';

class UserDao {
  final Database db;
  UserDao(this.db);

  Future<UserModel?> getUser(String id) async {
    final res = await db.query('users', where: 'id = ? AND (deleted_at IS NULL)', whereArgs: [id]);
    if (res.isNotEmpty) {
      final map = Map<String, dynamic>.from(res.first);
      if (!map.containsKey('name') && map.containsKey('display_name')) {
        map['name'] = map['display_name'];
      }
      return UserModel.fromMap(map);
    }
    return null;
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final res = await db.query('users', where: 'email = ? AND (deleted_at IS NULL)', whereArgs: [email.toLowerCase().trim()]);
    if (res.isNotEmpty) {
      final map = Map<String, dynamic>.from(res.first);
      if (!map.containsKey('name') && map.containsKey('display_name')) {
        map['name'] = map['display_name'];
      }
      return UserModel.fromMap(map);
    }
    return null;
  }

  Future<UserModel?> getUserByGoogleSub(String googleSub) async {
    final res = await db.query('users', where: 'google_sub = ? AND (deleted_at IS NULL)', whereArgs: [googleSub]);
    if (res.isNotEmpty) {
      final map = Map<String, dynamic>.from(res.first);
      if (!map.containsKey('name') && map.containsKey('display_name')) {
        map['name'] = map['display_name'];
      }
      return UserModel.fromMap(map);
    }
    return null;
  }

  Future<void> insertUser(UserModel user) async {
    await db.insert('users', {
      'id': user.id,
      'email': user.email,
      'first_name': user.name,
      'display_name': user.name,
      'google_sub': user.googleSub,
      'avatar_url': user.avatarUrl,
      'plan': user.plan,
      'account_status': user.status,
      'created_at': user.createdAt,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateUserPlan(String id, String plan, String status) async {
    await db.update('users', {
      'plan': plan,
      'account_status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> softDeleteAccount(String id) async {
    await db.update('users', {
      'account_status': 'DELETED',
      'deleted_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
  }

  /// Returns the most recently created non-deleted user (for local session restore).
  Future<UserModel?> getLastUser() async {
    final res = await db.query(
      'users',
      where: 'deleted_at IS NULL AND account_status != ?',
      whereArgs: ['DELETED'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (res.isNotEmpty) {
      final map = Map<String, dynamic>.from(res.first);
      if (!map.containsKey('name') && map.containsKey('display_name')) {
        map['name'] = map['display_name'];
      }
      return UserModel.fromMap(map);
    }
    return null;
  }
}
