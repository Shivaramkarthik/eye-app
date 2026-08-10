import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../services/database_service.dart';
import '../remote/sync_api.dart';

class SyncQueueService {
  static final SyncQueueService instance = SyncQueueService._internal();
  final SyncApi _syncApi = SyncApi();

  SyncQueueService._internal();

  Future<void> enqueueOperation({
    required String entityType,
    required String entityId,
    required String operation, // CREATE, UPDATE, DELETE
    required Map<String, dynamic> payload,
  }) async {
    final db = await DatabaseService.instance.database;
    final opId = 'op_${DateTime.now().millisecondsSinceEpoch}_${entityId.hashCode}';
    await db.insert('sync_queue', {
      'id': opId,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'payload': jsonEncode(payload),
      'attempt_count': 0,
      'status': 'PENDING',
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Attempt immediate background push
    flushQueue();
  }

  Future<void> flushQueue() async {
    try {
      final db = await DatabaseService.instance.database;
      final pending = await db.query('sync_queue', where: "status = 'PENDING'", orderBy: 'created_at ASC');
      if (pending.isEmpty) return;

      List<Map<String, dynamic>> operations = [];
      for (var row in pending) {
        operations.add({
          'operation_id': row['id'],
          'entity_type': row['entity_type'],
          'entity_id': row['entity_id'],
          'operation': row['operation'],
          'payload': jsonDecode(row['payload'] as String),
          'version': 1,
          'timestamp': row['created_at'],
        });
      }

      final result = await _syncApi.pushSyncQueue('device_mobile_client', operations);
      final processedResults = (result['results'] as List?) ?? [];

      for (var res in processedResults) {
        final opId = res['operation_id'];
        final status = res['status'];
        if (status == 'PROCESSED') {
          await db.delete('sync_queue', where: 'id = ?', whereArgs: [opId]);
        }
      }
    } catch (_) {
      // Mobile device is offline or server temporarily unavailable.
      // Operations remain safely queued in SQLite for automatic retry.
    }
  }
}
