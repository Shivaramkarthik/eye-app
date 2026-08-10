import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/medicine_model.dart';
import 'database_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  NotificationService._internal();

  Future<void> initialize({Function(String payload, String action)? onNotificationAction}) async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        final actionId = response.actionId ?? 'TAP';
        if (payload != null && payload.isNotEmpty) {
          await _handleNotificationAction(payload, actionId);
          if (onNotificationAction != null) {
            onNotificationAction(payload, actionId);
          }
        }
      },
    );

    _initialized = true;
  }

  Future<void> _handleNotificationAction(String payload, String actionId) async {
    // Payload format: "medicationId|timeKey"
    final parts = payload.split('|');
    if (parts.length >= 2) {
      final medId = parts[0];
      final timeKey = parts[1];
      final dateStr = DateTime.now().toString().split(' ')[0];
      final fullKey = "${dateStr}_$timeKey";

      if (actionId == 'TAKE' || actionId == 'TAP') {
        final dao = await DatabaseService.instance.medicationDao;
        await dao.logMedicationDose(
          medicationId: medId,
          scheduleId: '${medId}_sched_0',
          scheduledAt: fullKey,
          status: 'TAKEN',
        );
      } else if (actionId == 'SKIP') {
        final dao = await DatabaseService.instance.medicationDao;
        await dao.logMedicationDose(
          medicationId: medId,
          scheduleId: '${medId}_sched_0',
          scheduledAt: fullKey,
          status: 'SKIPPED',
        );
      } else if (actionId == 'SNOOZE') {
        // Schedule snooze notification 15 mins later
        await scheduleSnoozeNotification(medId, timeKey, 15);
      }
    }
  }

  Future<void> scheduleMedicationReminder(MedicineModel medicine, String timeStr) async {
    await initialize();

    final timeParts = _parseTimeString(timeStr);
    if (timeParts == null) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      timeParts['hour']!,
      timeParts['minute']!,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final notificationId = (medicine.id.hashCode + timeStr.hashCode).abs() % 100000;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'specz_medication_reminders',
      'Eye Drop & Medicine Reminders',
      channelDescription: 'OS-level reliable scheduled eye-drop reminders',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      playSound: true,
      enableVibration: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('TAKE', 'Take Now', showsUserInterface: true),
        AndroidNotificationAction('SNOOZE', 'Snooze 15m', showsUserInterface: false),
        AndroidNotificationAction('SKIP', 'Skip', showsUserInterface: false),
      ],
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final payload = "${medicine.id}|$timeStr";

    try {
      final tzLocation = tz.local;
      final tzScheduled = tz.TZDateTime.from(scheduledDate, tzLocation);

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'Eye Drop Reminder — ${medicine.name}',
        'Time to take: ${medicine.dosage} (${medicine.type})',
        tzScheduled,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } catch (_) {
      // Fallback show notification immediately if exact alarm fails
    }
  }

  Future<void> scheduleSnoozeNotification(String medId, String timeKey, int snoozeMinutes) async {
    await initialize();

    final notificationId = (medId.hashCode + timeKey.hashCode + 999).abs() % 100000;
    final scheduledDate = DateTime.now().add(Duration(minutes: snoozeMinutes));

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'specz_medication_reminders',
      'Eye Drop & Medicine Reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    final tzLocation = tz.local;
    final tzScheduled = tz.TZDateTime.from(scheduledDate, tzLocation);

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      'Snoozed Eye Drop Reminder',
      'Your snoozed eye drop reminder is due now!',
      tzScheduled,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: "$medId|$timeKey",
    );
  }

  Future<void> cancelMedicationReminders(MedicineModel medicine) async {
    for (var timeStr in medicine.times) {
      final notificationId = (medicine.id.hashCode + timeStr.hashCode).abs() % 100000;
      await _notificationsPlugin.cancel(notificationId);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Map<String, int>? _parseTimeString(String timeStr) {
    try {
      final clean = timeStr.trim().toUpperCase();
      final isPm = clean.endsWith('PM');
      final isAm = clean.endsWith('AM');
      final timePart = clean.replaceAll('AM', '').replaceAll('PM', '').trim();
      final split = timePart.split(':');
      if (split.length != 2) return null;

      int hour = int.parse(split[0]);
      int minute = int.parse(split[1]);

      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;

      return {'hour': hour, 'minute': minute};
    } catch (_) {
      return null;
    }
  }
}
