import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
  }

  // User operations
  Future<UserModel?> getUser(String userId) async {
    final db = await database;
    final res = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (res.isNotEmpty) {
      return UserModel.fromMap(res.first);
    }
    return null;
  }

  Future<void> updateUserPlan(String userId, String plan, String status, String? subId, String? nextRenewal) async {
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
    final db = await database;
    final res = await db.query('profiles', where: 'userId = ? AND isArchived = 0', whereArgs: [userId]);
    return res.map((e) => ProfileModel.fromMap(e)).toList();
  }

  Future<int> getActiveProfileCount(String userId) async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM profiles WHERE userId = ? AND isArchived = 0',
      [userId],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<void> insertProfile(ProfileModel profile) async {
    final db = await database;
    await db.insert('profiles', profile.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProfile(ProfileModel profile) async {
    final db = await database;
    await db.update('profiles', profile.toMap(), where: 'id = ?', whereArgs: [profile.id]);
  }

  /// Permanent cascade deletion rule:
  /// Deleting a profile removes all linked prescriptions, reports, medicines, and frees the profile slot immediately!
  Future<void> deleteProfileCascade(String profileId) async {
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
    final db = await database;
    final res = await db.query('prescriptions', where: 'profileId = ?', orderBy: 'prescriptionDate DESC', whereArgs: [profileId]);
    return res.map((e) => PrescriptionModel.fromMap(e)).toList();
  }

  Future<void> insertPrescription(PrescriptionModel prescription) async {
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
    final db = await database;
    final res = await db.query('reports', where: 'profileId = ?', orderBy: 'reportDate DESC', whereArgs: [profileId]);
    return res.map((e) => ReportModel.fromMap(e)).toList();
  }

  Future<void> insertReport(ReportModel report) async {
    final db = await database;
    await db.insert('reports', report.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Medicine operations
  Future<List<MedicineModel>> getMedicines(String profileId) async {
    final db = await database;
    final res = await db.query('medicines', where: 'profileId = ?', whereArgs: [profileId]);
    return res.map((e) => MedicineModel.fromMap(e)).toList();
  }

  Future<void> insertMedicine(MedicineModel medicine) async {
    final db = await database;
    await db.insert('medicines', medicine.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveUser(UserModel user) async {
    final db = await database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteMedicine(String id) async {
    final db = await database;
    await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleMedicineLog(String medicineId, String logKey) async {
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
