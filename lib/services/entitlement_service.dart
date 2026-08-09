import '../models/user_model.dart';
import 'database_service.dart';

class EntitlementService {
  static final EntitlementService instance = EntitlementService._internal();
  EntitlementService._internal();

  /// Check if user can add a new profile
  Future<bool> canCreateProfile(UserModel user) async {
    int currentCount = await DatabaseService.instance.getActiveProfileCount(user.id);
    int allowed = user.maxProfiles;
    return currentCount < allowed;
  }

  /// Get status message for profile capacity e.g. "1 of 1 profiles used" or "2 of 5 profiles used"
  Future<String> getProfileUsageText(UserModel user) async {
    int currentCount = await DatabaseService.instance.getActiveProfileCount(user.id);
    int allowed = user.maxProfiles;
    String tierLabel = user.isPlusActive ? "Specz Plus" : "Free Plan";
    return "$currentCount of $allowed profiles used ($tierLabel)";
  }

  /// Check if user can generate and download PDF report
  bool canGeneratePdf(UserModel user) {
    if (user.status == 'expired') return false;
    return user.isPlusActive;
  }

  /// Check if existing user state is read-only
  bool isReadOnlyMode(UserModel user) {
    return user.status == 'expired';
  }
}
