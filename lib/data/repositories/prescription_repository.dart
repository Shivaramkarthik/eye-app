import '../../models/prescription_model.dart';
import '../../services/database_service.dart';
import '../local/sync_queue.dart';
import '../remote/prescription_api.dart';

class PrescriptionRepository {
  final PrescriptionApi _remoteApi = PrescriptionApi();

  Future<List<PrescriptionModel>> getPrescriptions(String profileId, {String? userId}) async {
    // Read Local SQLite First
    final localList = await DatabaseService.instance.getPrescriptions(profileId, userId: userId);
    
    // Background cloud fetch
    _refreshRemote(profileId);

    return localList;
  }

  Future<void> savePrescription(PrescriptionModel prescription) async {
    // 1. Save to SQLite
    await DatabaseService.instance.insertPrescription(prescription);

    // 2. Enqueue for Cloud Sync
    await SyncQueueService.instance.enqueueOperation(
      entityType: 'prescription',
      entityId: prescription.id,
      operation: 'CREATE',
      payload: prescription.toMap(),
    );
  }

  Future<void> _refreshRemote(String profileId) async {
    try {
      final remoteList = await _remoteApi.getPrescriptions(profileId);
      for (var p in remoteList) {
        await DatabaseService.instance.insertPrescription(p);
      }
    } catch (_) {}
  }
}
