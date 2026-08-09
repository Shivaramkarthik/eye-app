import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/user_model.dart';
import '../models/profile_model.dart';
import '../models/prescription_model.dart';
import '../models/report_model.dart';
import '../models/medicine_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  // Web in-memory storage fallback
  UserModel? _webUser;
  final List<ProfileModel> _webProfiles = [];
  final List<PrescriptionModel> _webPrescriptions = [];
  final List<ReportModel> _webReports = [];
  final List<MedicineModel> _webMedicines = [];

  DatabaseService._internal() {
    if (kIsWeb) {
      _seedWebData();
    }
  }

  void _seedWebData() {
    final now = DateTime.now().toIso8601String();
    _webUser = UserModel(
      id: 'user_default',
      email: 'karthik@specz.co',
      name: 'Karthik',
      plan: 'free',
      status: 'free',
      createdAt: now,
    );

    _webProfiles.add(ProfileModel(
      id: 'prof_karthik',
      userId: 'user_default',
      name: 'Karthik',
      dob: '1992-05-14',
      gender: 'Male',
      type: 'Adult',
      relationship: 'Self',
      prescriptionType: 'Myopia',
      symptoms: ['Blurred vision', 'Eye strain'],
      blurredVisionType: 'Distance',
      isArchived: false,
      createdAt: now,
    ));

    _webPrescriptions.add(PrescriptionModel(
      id: 'presc_1',
      profileId: 'prof_karthik',
      userId: 'user_default',
      prescriptionDate: '2026-06-15',
      doctorName: 'Dr. Ananya Sharma',
      clinicName: 'Vision Eye Care Institute',
      rightSph: -2.25,
      rightCyl: -0.75,
      rightAxis: 180,
      leftSph: -2.50,
      leftCyl: -0.50,
      leftAxis: 175,
      addPower: 0.0,
      pd: 63.0,
      notes: 'Anti-reflective coating recommended for computer work.',
      isCurrent: true,
      createdAt: now,
    ));

    _webMedicines.add(MedicineModel(
      id: 'med_1',
      profileId: 'prof_karthik',
      userId: 'user_default',
      name: 'Refresh Tears Lubricant Drop',
      type: 'Drop',
      dosage: '1 drop in both eyes',
      startDate: '2026-08-01',
      times: ['09:00 AM', '09:00 PM'],
      tone: 'Soft Chime',
      vibrationEnabled: true,
      active: true,
      completedLogs: [],
      createdAt: now,
    ));
  }

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError("Sqflite database is not supported on web. Use in-memory mocks.");
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path = '';
    if (kIsWeb) {
      path = 'specz_co_web.db';
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      path = join(docsDir.path, 'specz_co.db');
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        name TEXT NOT NULL,
        plan TEXT NOT NULL DEFAULT 'free',
        subscriptionId TEXT,
        status TEXT NOT NULL DEFAULT 'free',
        nextRenewalDate TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Profiles table
    await db.execute('''
      CREATE TABLE profiles (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        dob TEXT NOT NULL,
        gender TEXT NOT NULL,
        type TEXT NOT NULL,
        relationship TEXT NOT NULL,
        prescriptionType TEXT,
        symptoms TEXT,
        blurredVisionType TEXT,
        isArchived INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // Prescriptions table
    await db.execute('''
      CREATE TABLE prescriptions (
        id TEXT PRIMARY KEY,
        profileId TEXT NOT NULL,
        userId TEXT NOT NULL,
        prescriptionDate TEXT NOT NULL,
        doctorName TEXT,
        clinicName TEXT,
        rightSph REAL,
        rightCyl REAL,
        rightAxis INTEGER,
        leftSph REAL,
        leftCyl REAL,
        leftAxis INTEGER,
        addPower REAL,
        pd REAL,
        notes TEXT,
        imageUrl TEXT,
        isCurrent INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');

    // Reports table
    await db.execute('''
      CREATE TABLE reports (
        id TEXT PRIMARY KEY,
        profileId TEXT NOT NULL,
        userId TEXT NOT NULL,
        reportDate TEXT NOT NULL,
        title TEXT NOT NULL,
        clinicName TEXT,
        filePath TEXT,
        notes TEXT,
        followUpDate TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Medicines table
    await db.execute('''
      CREATE TABLE medicines (
        id TEXT PRIMARY KEY,
        profileId TEXT NOT NULL,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        dosage TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT,
        times TEXT NOT NULL,
        tone TEXT NOT NULL DEFAULT 'Soft Chime',
        vibrationEnabled INTEGER NOT NULL DEFAULT 1,
        active INTEGER NOT NULL DEFAULT 1,
        completedLogs TEXT NOT NULL DEFAULT '[]',
        createdAt TEXT NOT NULL
      )
    ''');

    // Seed default user & profile for Karthik
    final now = DateTime.now().toIso8601String();
    await db.insert('users', {
      'id': 'user_default',
      'email': 'karthik@specz.co',
      'name': 'Karthik',
      'plan': 'free',
      'status': 'free',
      'createdAt': now,
    });

    await db.insert('profiles', {
      'id': 'prof_karthik',
      'userId': 'user_default',
      'name': 'Karthik',
      'dob': '1992-05-14',
      'gender': 'Male',
      'type': 'Adult',
      'relationship': 'Self',
      'prescriptionType': 'Myopia',
      'symptoms': '["Blurred vision","Eye strain"]',
      'blurredVisionType': 'Distance',
      'isArchived': 0,
      'createdAt': now,
    });

    // Seed initial prescription
    await db.insert('prescriptions', {
      'id': 'presc_1',
      'profileId': 'prof_karthik',
      'userId': 'user_default',
      'prescriptionDate': '2026-06-15',
      'doctorName': 'Dr. Ananya Sharma',
      'clinicName': 'Vision Eye Care Institute',
      'rightSph': -2.25,
      'rightCyl': -0.75,
      'rightAxis': 180,
      'leftSph': -2.50,
      'leftCyl': -0.50,
      'leftAxis': 175,
      'addPower': 0.0,
      'pd': 63.0,
      'notes': 'Anti-reflective coating recommended for computer work.',
      'isCurrent': 1,
      'createdAt': now,
    });

    // Seed initial medicine
    await db.insert('medicines', {
      'id': 'med_1',
      'profileId': 'prof_karthik',
      'userId': 'user_default',
      'name': 'Refresh Tears Lubricant Drop',
      'type': 'Drop',
      'dosage': '1 drop in both eyes',
      'startDate': '2026-08-01',
      'times': '["09:00 AM","09:00 PM"]',
      'tone': 'Soft Chime',
      'vibrationEnabled': 1,
      'active': 1,
      'completedLogs': '[]',
      'createdAt': now,
    });
  }

  // User operations
  Future<UserModel?> getUser(String userId) async {
    if (kIsWeb) {
      if (_webUser?.id == userId) return _webUser;
      return null;
    }
    final db = await database;
    final res = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (res.isNotEmpty) {
      return UserModel.fromMap(res.first);
    }
    return null;
  }

  Future<void> updateUserPlan(String userId, String plan, String status, String? subId, String? nextRenewal) async {
    if (kIsWeb) {
      if (_webUser != null && _webUser!.id == userId) {
        _webUser = UserModel(
          id: _webUser!.id,
          email: _webUser!.email,
          name: _webUser!.name,
          plan: plan,
          status: status,
          subscriptionId: subId,
          nextRenewalDate: nextRenewal,
          createdAt: _webUser!.createdAt,
        );
      }
      return;
    }
    final db = await database;
    await db.update(
      'users',
      {
        'plan': plan,
        'status': status,
        'subscriptionId': subId,
        'nextRenewalDate': nextRenewal,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Profile operations
  Future<List<ProfileModel>> getProfiles(String userId) async {
    if (kIsWeb) {
      return _webProfiles.where((p) => p.userId == userId && !p.isArchived).toList();
    }
    final db = await database;
    final res = await db.query('profiles', where: 'userId = ? AND isArchived = 0', whereArgs: [userId]);
    return res.map((e) => ProfileModel.fromMap(e)).toList();
  }

  Future<int> getActiveProfileCount(String userId) async {
    if (kIsWeb) {
      return _webProfiles.where((p) => p.userId == userId && !p.isArchived).length;
    }
    final db = await database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM profiles WHERE userId = ? AND isArchived = 0',
      [userId],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<void> insertProfile(ProfileModel profile) async {
    if (kIsWeb) {
      _webProfiles.removeWhere((p) => p.id == profile.id);
      _webProfiles.add(profile);
      return;
    }
    final db = await database;
    await db.insert('profiles', profile.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProfile(ProfileModel profile) async {
    if (kIsWeb) {
      _webProfiles.removeWhere((p) => p.id == profile.id);
      _webProfiles.add(profile);
      return;
    }
    final db = await database;
    await db.update('profiles', profile.toMap(), where: 'id = ?', whereArgs: [profile.id]);
  }

  /// Permanent cascade deletion rule:
  /// Deleting a profile removes all linked prescriptions, reports, medicines, and frees the profile slot immediately!
  Future<void> deleteProfileCascade(String profileId) async {
    if (kIsWeb) {
      _webPrescriptions.removeWhere((p) => p.profileId == profileId);
      _webReports.removeWhere((r) => r.profileId == profileId);
      _webMedicines.removeWhere((m) => m.profileId == profileId);
      _webProfiles.removeWhere((p) => p.id == profileId);
      return;
    }
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('prescriptions', where: 'profileId = ?', whereArgs: [profileId]);
      await txn.delete('reports', where: 'profileId = ?', whereArgs: [profileId]);
      await txn.delete('medicines', where: 'profileId = ?', whereArgs: [profileId]);
      await txn.delete('profiles', where: 'id = ?', whereArgs: [profileId]);
    });
  }

  // Prescription operations
  Future<List<PrescriptionModel>> getPrescriptions(String profileId) async {
    if (kIsWeb) {
      final list = _webPrescriptions.where((p) => p.profileId == profileId).toList();
      list.sort((a, b) => b.prescriptionDate.compareTo(a.prescriptionDate));
      return list;
    }
    final db = await database;
    final res = await db.query('prescriptions', where: 'profileId = ?', orderBy: 'prescriptionDate DESC', whereArgs: [profileId]);
    return res.map((e) => PrescriptionModel.fromMap(e)).toList();
  }

  Future<void> insertPrescription(PrescriptionModel prescription) async {
    if (kIsWeb) {
      if (prescription.isCurrent) {
        for (var i = 0; i < _webPrescriptions.length; i++) {
          if (_webPrescriptions[i].profileId == prescription.profileId) {
            _webPrescriptions[i] = PrescriptionModel(
              id: _webPrescriptions[i].id,
              profileId: _webPrescriptions[i].profileId,
              userId: _webPrescriptions[i].userId,
              prescriptionDate: _webPrescriptions[i].prescriptionDate,
              doctorName: _webPrescriptions[i].doctorName,
              clinicName: _webPrescriptions[i].clinicName,
              rightSph: _webPrescriptions[i].rightSph,
              rightCyl: _webPrescriptions[i].rightCyl,
              rightAxis: _webPrescriptions[i].rightAxis,
              leftSph: _webPrescriptions[i].leftSph,
              leftCyl: _webPrescriptions[i].leftCyl,
              leftAxis: _webPrescriptions[i].leftAxis,
              addPower: _webPrescriptions[i].addPower,
              pd: _webPrescriptions[i].pd,
              notes: _webPrescriptions[i].notes,
              imageUrl: _webPrescriptions[i].imageUrl,
              isCurrent: false,
              createdAt: _webPrescriptions[i].createdAt,
            );
          }
        }
      }
      _webPrescriptions.removeWhere((p) => p.id == prescription.id);
      _webPrescriptions.add(prescription);
      return;
    }
    final db = await database;
    await db.transaction((txn) async {
      if (prescription.isCurrent) {
        await txn.update('prescriptions', {'isCurrent': 0}, where: 'profileId = ?', whereArgs: [prescription.profileId]);
      }
      await txn.insert('prescriptions', prescription.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  // Report operations
  Future<List<ReportModel>> getReports(String profileId) async {
    if (kIsWeb) {
      final list = _webReports.where((r) => r.profileId == profileId).toList();
      list.sort((a, b) => b.reportDate.compareTo(a.reportDate));
      return list;
    }
    final db = await database;
    final res = await db.query('reports', where: 'profileId = ?', orderBy: 'reportDate DESC', whereArgs: [profileId]);
    return res.map((e) => ReportModel.fromMap(e)).toList();
  }

  Future<void> insertReport(ReportModel report) async {
    if (kIsWeb) {
      _webReports.removeWhere((r) => r.id == report.id);
      _webReports.add(report);
      return;
    }
    final db = await database;
    await db.insert('reports', report.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Medicine operations
  Future<List<MedicineModel>> getMedicines(String profileId) async {
    if (kIsWeb) {
      return _webMedicines.where((m) => m.profileId == profileId).toList();
    }
    final db = await database;
    final res = await db.query('medicines', where: 'profileId = ?', whereArgs: [profileId]);
    return res.map((e) => MedicineModel.fromMap(e)).toList();
  }

  Future<void> insertMedicine(MedicineModel medicine) async {
    if (kIsWeb) {
      _webMedicines.removeWhere((m) => m.id == medicine.id);
      _webMedicines.add(medicine);
      return;
    }
    final db = await database;
    await db.insert('medicines', medicine.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> toggleMedicineLog(String medicineId, String logKey) async {
    if (kIsWeb) {
      final idx = _webMedicines.indexWhere((m) => m.id == medicineId);
      if (idx != -1) {
        final med = _webMedicines[idx];
        List<String> logs = List<String>.from(med.completedLogs);
        if (logs.contains(logKey)) {
          logs.remove(logKey);
        } else {
          logs.add(logKey);
        }
        _webMedicines[idx] = MedicineModel(
          id: med.id,
          profileId: med.profileId,
          userId: med.userId,
          name: med.name,
          type: med.type,
          dosage: med.dosage,
          startDate: med.startDate,
          endDate: med.endDate,
          times: med.times,
          tone: med.tone,
          vibrationEnabled: med.vibrationEnabled,
          active: med.active,
          completedLogs: logs,
          createdAt: med.createdAt,
        );
      }
      return;
    }
    final db = await database;
    final res = await db.query('medicines', where: 'id = ?', whereArgs: [medicineId]);
    if (res.isNotEmpty) {
      final med = MedicineModel.fromMap(res.first);
      List<String> logs = List<String>.from(med.completedLogs);
      if (logs.contains(logKey)) {
        logs.remove(logKey);
      } else {
        logs.add(logKey);
      }
      await db.update('medicines', {'completedLogs': jsonEncode(logs)}, where: 'id = ?', whereArgs: [medicineId]);
    }
  }
}
