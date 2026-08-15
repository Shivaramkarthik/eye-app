import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/user_model.dart';
import '../models/profile_model.dart';
import '../models/prescription_model.dart';
import '../models/report_model.dart';
import '../models/medicine_model.dart';
import '../models/subscription_model.dart';
import '../data/local/migration_manager.dart';
import '../data/local/dao/user_dao.dart';
import '../data/local/dao/profile_dao.dart';
import '../data/local/dao/prescription_dao.dart';
import '../data/local/dao/medication_dao.dart';
import '../data/local/dao/report_dao.dart';
import '../data/local/dao/subscription_dao.dart';
import '../data/local/dao/score_dao.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final path = join(docsDir.path, 'specz_co.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await DatabaseMigrationManager.createV2Schema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await DatabaseMigrationManager.createV2Schema(db);
          await DatabaseMigrationManager.migrateFromV1ToV2(db);
        }
        if (oldVersion < 3) {
          // Add Google Sign-In fields to users table
          try {
            await db.execute('ALTER TABLE users ADD COLUMN google_sub TEXT');
          } catch (_) {} // Column may already exist
          try {
            await db.execute('ALTER TABLE users ADD COLUMN avatar_url TEXT');
          } catch (_) {} // Column may already exist
        }
      },
    );
  }

  // DAOs
  Future<UserDao> get userDao async => UserDao(await database);
  Future<ProfileDao> get profileDao async => ProfileDao(await database);
  Future<PrescriptionDao> get prescriptionDao async => PrescriptionDao(await database);
  Future<MedicationDao> get medicationDao async => MedicationDao(await database);
  Future<ReportDao> get reportDao async => ReportDao(await database);
  Future<SubscriptionDao> get subscriptionDao async => SubscriptionDao(await database);
  Future<ScoreDao> get scoreDao async => ScoreDao(await database);

  // Legacy wrapper operations for backwards compatibility
  Future<UserModel?> getUser(String userId) async {
    final dao = await userDao;
    return dao.getUser(userId);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final dao = await userDao;
    return dao.getUserByEmail(email);
  }

  Future<void> saveUser(UserModel user) async {
    final dao = await userDao;
    await dao.insertUser(user);
  }

  /// Returns the most recently created local user (for session restore without backend).
  Future<UserModel?> getLastUser() async {
    final dao = await userDao;
    return dao.getLastUser();
  }

  Future<void> updateUserPlan(String userId, String plan, String status, String? subId, String? nextRenewal) async {
    final dao = await userDao;
    await dao.updateUserPlan(userId, plan, status);
    if (subId != null) {
      final subDao = await subscriptionDao;
      await subDao.insertSubscription(
        SubscriptionModel(
          id: subId,
          userId: userId,
          plan: plan,
          status: status,
          startedAt: DateTime.now().toIso8601String(),
          expiresAt: nextRenewal,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
    }
  }

  Future<List<ProfileModel>> getProfiles(String userId) async {
    final dao = await profileDao;
    return dao.getProfilesForUser(userId);
  }

  Future<int> getActiveProfileCount(String userId) async {
    final dao = await profileDao;
    return dao.getActiveProfileCount(userId);
  }

  Future<void> insertProfile(ProfileModel profile) async {
    final dao = await profileDao;
    await dao.insertProfile(profile);
  }

  Future<void> updateProfile(ProfileModel profile) async {
    final dao = await profileDao;
    await dao.updateProfile(profile);
  }

  Future<void> deleteProfileCascade(String profileId, {String? userId}) async {
    final dao = await profileDao;
    if (userId != null && userId.isNotEmpty) {
      await dao.deleteProfileCascade(profileId, userId);
    } else {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete('profile_symptoms', where: 'profile_id = ?', whereArgs: [profileId]);
        await txn.delete('prescription_eye_values', where: 'prescription_id IN (SELECT id FROM prescriptions WHERE profile_id = ?)', whereArgs: [profileId]);
        await txn.delete('prescriptions', where: 'profile_id = ?', whereArgs: [profileId]);
        await txn.delete('medication_logs', where: 'medication_id IN (SELECT id FROM medications WHERE profile_id = ?)', whereArgs: [profileId]);
        await txn.delete('medication_schedules', where: 'medication_id IN (SELECT id FROM medications WHERE profile_id = ?)', whereArgs: [profileId]);
        await txn.delete('medications', where: 'profile_id = ?', whereArgs: [profileId]);
        await txn.delete('reports', where: 'profile_id = ?', whereArgs: [profileId]);
        await txn.delete('profiles', where: 'id = ?', whereArgs: [profileId]);
      });
    }
  }

  Future<List<PrescriptionModel>> getPrescriptions(String profileId, {String? userId}) async {
    final db = await database;
    final res = await db.query(
      'prescriptions',
      where: userId != null && userId.isNotEmpty ? 'profile_id = ? AND user_id = ?' : 'profile_id = ?',
      orderBy: 'prescription_date DESC',
      whereArgs: userId != null && userId.isNotEmpty ? [profileId, userId] : [profileId],
    );

    List<PrescriptionModel> list = [];
    for (var row in res) {
      final pId = row['id'] as String;
      final eyeValues = await db.query('prescription_eye_values', where: 'prescription_id = ?', whereArgs: [pId]);

      double? rSph, rCyl, lSph, lCyl;
      int? rAxis, lAxis;

      for (var ev in eyeValues) {
        final eye = ev['eye'] as String?;
        if (eye == 'OD') {
          rSph = (ev['sph'] as num?)?.toDouble();
          rCyl = (ev['cyl'] as num?)?.toDouble();
          rAxis = (ev['axis'] as num?)?.toInt();
        } else if (eye == 'OS') {
          lSph = (ev['sph'] as num?)?.toDouble();
          lCyl = (ev['cyl'] as num?)?.toDouble();
          lAxis = (ev['axis'] as num?)?.toInt();
        }
      }

      Map<String, dynamic> mutableMap = Map<String, dynamic>.from(row);
      mutableMap['profileId'] = row['profile_id'];
      mutableMap['userId'] = row['user_id'];
      mutableMap['prescriptionDate'] = row['prescription_date'];
      mutableMap['doctorName'] = row['doctor_name'];
      mutableMap['clinicName'] = row['clinic_name'];
      mutableMap['addPower'] = row['add_power'];
      mutableMap['imageUrl'] = row['image_url'];
      mutableMap['isCurrent'] = row['is_current'];
      mutableMap['createdAt'] = row['created_at'];

      mutableMap['rightSph'] = rSph;
      mutableMap['rightCyl'] = rCyl;
      mutableMap['rightAxis'] = rAxis;
      mutableMap['leftSph'] = lSph;
      mutableMap['leftCyl'] = lCyl;
      mutableMap['leftAxis'] = lAxis;

      list.add(PrescriptionModel.fromMap(mutableMap));
    }
    return list;
  }

  Future<void> insertPrescription(PrescriptionModel prescription) async {
    final dao = await prescriptionDao;
    await dao.insertPrescription(prescription);
  }

  Future<List<ReportModel>> getReports(String profileId, {String? userId}) async {
    final db = await database;
    final res = await db.query(
      'reports',
      where: userId != null && userId.isNotEmpty ? 'profile_id = ? AND user_id = ?' : 'profile_id = ?',
      orderBy: 'report_date DESC',
      whereArgs: userId != null && userId.isNotEmpty ? [profileId, userId] : [profileId],
    );

    return res.map((r) {
      Map<String, dynamic> mutableMap = Map<String, dynamic>.from(r);
      mutableMap['profileId'] = r['profile_id'];
      mutableMap['userId'] = r['user_id'];
      mutableMap['reportDate'] = r['report_date'];
      mutableMap['clinicName'] = r['clinic_name'];
      mutableMap['filePath'] = r['file_path'];
      mutableMap['followUpDate'] = r['follow_up_date'];
      mutableMap['createdAt'] = r['created_at'];
      return ReportModel.fromMap(mutableMap);
    }).toList();
  }

  Future<void> insertReport(ReportModel report) async {
    final dao = await reportDao;
    await dao.insertReport(report);
  }

  Future<List<MedicineModel>> getMedicines(String profileId, {String? userId}) async {
    final dao = await medicationDao;
    final uId = userId ?? '';
    if (uId.isNotEmpty) {
      return dao.getMedicinesForProfile(profileId, uId);
    } else {
      final db = await database;
      final res = await db.query('medications', where: 'profile_id = ?', whereArgs: [profileId]);
      List<MedicineModel> list = [];
      for (var m in res) {
        final medId = m['id'] as String;
        final schedules = await db.query('medication_schedules', where: 'medication_id = ? AND enabled = 1', whereArgs: [medId]);
        List<String> times = schedules.map((s) => s['time'] as String).toList();

        final tone = schedules.isNotEmpty ? (schedules.first['tone'] as String) : 'Soft Chime';
        final vib = schedules.isNotEmpty ? ((schedules.first['vibration_enabled'] == 1) || (schedules.first['vibration_enabled'] == true)) : true;

        final logs = await db.query('medication_logs', where: 'medication_id = ? AND status = ?', whereArgs: [medId, 'TAKEN']);
        List<String> completedLogs = logs.map((l) => l['scheduled_at'] as String).toList();

        Map<String, dynamic> mutableMap = Map<String, dynamic>.from(m);
        mutableMap['profileId'] = m['profile_id'];
        mutableMap['userId'] = m['user_id'];
        mutableMap['startDate'] = m['start_date'];
        mutableMap['endDate'] = m['end_date'];
        mutableMap['times'] = times;
        mutableMap['tone'] = tone;
        mutableMap['vibrationEnabled'] = vib;
        mutableMap['active'] = m['active'];
        mutableMap['completedLogs'] = completedLogs;
        mutableMap['createdAt'] = m['created_at'];

        list.add(MedicineModel.fromMap(mutableMap));
      }
      return list;
    }
  }

  Future<void> insertMedicine(MedicineModel medicine) async {
    final dao = await medicationDao;
    await dao.insertMedicine(medicine);
  }

  Future<void> deleteMedicine(String id, {String? userId}) async {
    final dao = await medicationDao;
    if (userId != null && userId.isNotEmpty) {
      await dao.deleteMedicine(id, userId);
    } else {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete('medication_logs', where: 'medication_id = ?', whereArgs: [id]);
        await txn.delete('medication_schedules', where: 'medication_id = ?', whereArgs: [id]);
        await txn.delete('medications', where: 'id = ?', whereArgs: [id]);
      });
    }
  }

  Future<void> toggleMedicineLog(String medicineId, String logKey) async {
    final dao = await medicationDao;
    final db = await database;
    final check = await db.query('medication_logs', where: 'medication_id = ? AND scheduled_at = ?', whereArgs: [medicineId, logKey]);
    if (check.isNotEmpty) {
      await db.delete('medication_logs', where: 'medication_id = ? AND scheduled_at = ?', whereArgs: [medicineId, logKey]);
    } else {
      await dao.logMedicationDose(
        medicationId: medicineId,
        scheduleId: '${medicineId}_sched_0',
        scheduledAt: logKey,
        status: 'TAKEN',
      );
    }
  }
}
