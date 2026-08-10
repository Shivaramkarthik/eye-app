import '../../models/medicine_model.dart';
import '../../services/database_service.dart';
import '../local/sync_queue.dart';
import '../remote/medication_api.dart';

class MedicationRepository {
  final MedicationApi _remoteApi = MedicationApi();

  Future<List<MedicineModel>> getMedicines(String profileId, {String? userId}) async {
    final localList = await DatabaseService.instance.getMedicines(profileId, userId: userId);
    _refreshRemote(profileId);
    return localList;
  }

  Future<void> saveMedicine(MedicineModel medicine) async {
    // 1. Save to SQLite
    await DatabaseService.instance.insertMedicine(medicine);

    // 2. Enqueue for Cloud Sync
    await SyncQueueService.instance.enqueueOperation(
      entityType: 'medication',
      entityId: medicine.id,
      operation: 'CREATE',
      payload: medicine.toMap(),
    );
  }

  Future<void> deleteMedicine(String id, {String? userId}) async {
    await DatabaseService.instance.deleteMedicine(id, userId: userId);

    await SyncQueueService.instance.enqueueOperation(
      entityType: 'medication',
      entityId: id,
      operation: 'DELETE',
      payload: {'id': id, 'userId': userId},
    );
  }

  Future<void> logDose(String medicineId, String logKey) async {
    await DatabaseService.instance.toggleMedicineLog(medicineId, logKey);

    await SyncQueueService.instance.enqueueOperation(
      entityType: 'medication_log',
      entityId: '${medicineId}_$logKey',
      operation: 'CREATE',
      payload: {
        'medicationId': medicineId,
        'scheduledAt': logKey,
        'status': 'TAKEN',
      },
    );
  }

  Future<void> _refreshRemote(String profileId) async {
    try {
      final remoteList = await _remoteApi.getMedications(profileId);
      for (var m in remoteList) {
        await DatabaseService.instance.insertMedicine(m);
      }
    } catch (_) {}
  }
}
