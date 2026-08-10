import '../models/medicine_model.dart';
import 'notification_service.dart';
import 'database_service.dart';

class NotificationScheduler {
  static final NotificationScheduler instance = NotificationScheduler._internal();
  NotificationScheduler._internal();

  Future<void> scheduleMedicine(MedicineModel medicine) async {
    if (!medicine.active) {
      await cancelMedicine(medicine);
      return;
    }
    for (var timeStr in medicine.times) {
      await NotificationService.instance.scheduleMedicationReminder(medicine, timeStr);
    }
  }

  Future<void> cancelMedicine(MedicineModel medicine) async {
    await NotificationService.instance.cancelMedicationReminders(medicine);
  }

  Future<void> rescheduleAllActiveMedicinesForUser(String userId) async {
    final profiles = await DatabaseService.instance.getProfiles(userId);
    for (var p in profiles) {
      final medicines = await DatabaseService.instance.getMedicines(p.id, userId: userId);
      for (var med in medicines) {
        if (med.active) {
          await scheduleMedicine(med);
        }
      }
    }
  }
}
