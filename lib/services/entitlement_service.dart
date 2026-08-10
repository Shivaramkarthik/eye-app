import '../models/user_model.dart';
import 'database_service.dart';

class EntitlementService {
  static final EntitlementService instance = EntitlementService._internal();
  EntitlementService._internal();

  /// Check if user can add a new profile (Free = 1 profile, Plus = up to 5 profiles)
  Future<bool> canCreateProfile(UserModel user) async {
    int currentCount = await DatabaseService.instance.getActiveProfileCount(user.id);
    int allowed = user.isPlusActive ? 5 : 1;
    return currentCount < allowed;
  }

  /// Get capacity usage string e.g. "1 of 1 profiles used (Free Plan)"
  Future<String> getProfileUsageText(UserModel user) async {
    int currentCount = await DatabaseService.instance.getActiveProfileCount(user.id);
    int allowed = user.isPlusActive ? 5 : 1;
    String tierLabel = user.isPlusActive ? "Specz Plus" : "Free Plan";
    return "$currentCount of $allowed profiles used ($tierLabel)";
  }

  /// Check if user can generate and download PDF reports
  bool canGeneratePdf(UserModel user) {
    if (user.status == 'expired') return false;
    return user.isPlusActive;
  }

  /// Check if existing user state is read-only
  bool isReadOnlyMode(UserModel user) {
    return user.status == 'expired';
  }
}
