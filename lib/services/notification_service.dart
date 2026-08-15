import 'dart:async';
import 'dart:typed_data';
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
    _detectAndSetLocalTimezone();

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

    // Create High-Priority Alarm Notification Channel for Eye Drop Alarms
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'specz_medication_reminders',
        'Eye Drop & Medicine Alarms',
        description: 'Wakeup-style persistent eye drop alarm clock reminders',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      );

      await androidImplementation.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  void _detectAndSetLocalTimezone() {
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      for (var location in tz.timeZoneDatabase.locations.values) {
        final tzNow = tz.TZDateTime.now(location);
        if (tzNow.timeZoneOffset == offset) {
          tz.setLocalLocation(location);
          return;
        }
      }
    } catch (_) {}
  }

  Future<void> showImmediateTestNotification(MedicineModel medicine) async {
    await initialize();
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'specz_medication_reminders',
      'Eye Drop & Medicine Alarms',
      channelDescription: 'Wakeup-style persistent eye drop alarm clock reminders',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      playSound: true,
      enableVibration: true,
      additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT: loops sound like alarm clock!
    );
    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 10000,
      '⏰ EYE DROP ALARM — ${medicine.name}',
      'Time to take: ${medicine.dosage} (${medicine.type})',
      platformDetails,
    );
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

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'specz_medication_reminders',
      'Eye Drop & Medicine Alarms',
      channelDescription: 'Wakeup-style persistent eye drop alarm clock reminders',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      playSound: true,
      enableVibration: true,
      additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT: loops sound like alarm clock!
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('TAKE', 'Take Now', showsUserInterface: true),
        const AndroidNotificationAction('SNOOZE', 'Snooze 15m', showsUserInterface: false),
        const AndroidNotificationAction('SKIP', 'Skip', showsUserInterface: false),
      ],
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final payload = "${medicine.id}|$timeStr";

    final tzScheduled = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledDate.hour,
      scheduledDate.minute,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        '⏰ EYE DROP ALARM — ${medicine.name}',
        'Time to take: ${medicine.dosage} (${medicine.type})',
        tzScheduled,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } catch (_) {
      try {
        await _notificationsPlugin.zonedSchedule(
          notificationId,
          '⏰ EYE DROP ALARM — ${medicine.name}',
          'Time to take: ${medicine.dosage} (${medicine.type})',
          tzScheduled,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
      } catch (_) {
        try {
          await _notificationsPlugin.zonedSchedule(
            notificationId,
            '⏰ EYE DROP ALARM — ${medicine.name}',
            'Time to take: ${medicine.dosage} (${medicine.type})',
            tzScheduled,
            platformDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: payload,
          );
        } catch (_) {}
      }
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

    final tzScheduled = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledDate.hour,
      scheduledDate.minute,
      scheduledDate.second,
    );

    try {
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
    } catch (_) {
      try {
        await _notificationsPlugin.zonedSchedule(
          notificationId,
          'Snoozed Eye Drop Reminder',
          'Your snoozed eye drop reminder is due now!',
          tzScheduled,
          const NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: "$medId|$timeKey",
        );
      } catch (_) {}
    }
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
