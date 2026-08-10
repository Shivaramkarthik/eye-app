import '../../models/profile_model.dart';
import '../../services/database_service.dart';
import '../local/sync_queue.dart';
import '../remote/profile_api.dart';

class ProfileRepository {
  final ProfileApi _remoteApi = ProfileApi();

  Future<List<ProfileModel>> getProfiles(String userId) async {
    // Local SQLite First
    final localProfiles = await DatabaseService.instance.getProfiles(userId);
    
    // Background cloud refresh if available
    _refreshRemote(userId);
    
    return localProfiles;
  }

  Future<void> saveProfile(ProfileModel profile) async {
    // 1. Save to SQLite
    await DatabaseService.instance.insertProfile(profile);

    // 2. Enqueue for Cloud Sync
    await SyncQueueService.instance.enqueueOperation(
      entityType: 'profile',
      entityId: profile.id,
      operation: 'CREATE',
      payload: profile.toMap(),
    );
  }

  Future<void> deleteProfile(String profileId, String userId) async {
    // 1. Delete locally from SQLite
    await DatabaseService.instance.deleteProfileCascade(profileId, userId: userId);

    // 2. Enqueue for Cloud Sync
    await SyncQueueService.instance.enqueueOperation(
      entityType: 'profile',
      entityId: profileId,
      operation: 'DELETE',
      payload: {'id': profileId, 'userId': userId},
    );
  }

  Future<void> _refreshRemote(String userId) async {
    try {
      final remoteProfiles = await _remoteApi.getProfiles();
      for (var p in remoteProfiles) {
        await DatabaseService.instance.insertProfile(p);
      }
    } catch (_) {}
  }
}
