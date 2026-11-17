import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../data/models.dart';

class Reminder {
  const Reminder(this.id, this.minute, this.title, this.body, this.tab);
  final int id;
  final int minute;
  final String title;
  final String body;
  final int tab;
}

List<Reminder> reminderPlan(DayliSettings s) {
  if (!s.notifications) return [];
  return [
    if (s.waterReminder)
      for (var hour = 8; hour <= 20; hour += 2)
        Reminder(
          100 + hour,
          hour * 60,
          'Bir bardak suya ne dersin?',
          'Günlük su hedefine küçük bir adım ekle.',
          0,
        ),
    if (s.taskReminder)
      const Reminder(
        200,
        20 * 60,
        'Gününe küçük bir bakış',
        'Bugünkü görevlerini gözden geçirmek için bir an ayır.',
        0,
      ),
    if (s.habitReminder)
      Reminder(
        300,
        s.habitMinute,
        'Kendin için küçük bir adım',
        'Bugünkü alışkanlıklarına zaman ayır.',
        1,
      ),
  ];
}

tz.TZDateTime nextReminder(tz.Location location, DateTime now, int minute) {
  final local = tz.TZDateTime.from(now, location);
  var result = tz.TZDateTime(
    location,
    local.year,
    local.month,
    local.day,
    minute ~/ 60,
    minute % 60,
  );
  if (!result.isAfter(local)) {
    result = tz.TZDateTime(
      location,
      local.year,
      local.month,
      local.day + 1,
      minute ~/ 60,
      minute % 60,
    );
  }
  return result;
}

class DayliNotifications extends ChangeNotifier {
  DayliNotifications({this.disabled = false});
  final bool disabled;
  final _plugin = FlutterLocalNotificationsPlugin();
  final requestedTab = ValueNotifier<int?>(null);
  bool _initialized = false;
  bool _disposed = false;
  Future<void> _queue = Future.value();
  bool permissionGranted = false;
  String? error;

  Future<void> initialize() async {
    if (disabled || _initialized) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) => _open(response.payload),
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _open(launch?.notificationResponse?.payload);
    }
    _initialized = true;
  }

  void _open(String? payload) {
    if (!_disposed) {
      requestedTab.value = null;
      requestedTab.value = payload == '1' ? 1 : 0;
    }
  }

  Future<bool> requestPermission() async {
    if (disabled) return false;
    try {
      await initialize();
      if (Platform.isAndroid) {
        permissionGranted =
            await _plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()!
                .requestNotificationsPermission() ??
            false;
      } else if (Platform.isIOS) {
        permissionGranted =
            await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()!
                .requestPermissions(alert: true, badge: false, sound: true) ??
            false;
      }
      error = permissionGranted
          ? null
          : 'Bildirim izni kapalı. Cihaz ayarlarından Rutin Defterim bildirimlerine izin verebilirsin.';
    } catch (_) {
      error = 'Bildirim izni kontrol edilemedi. Tekrar deneyebilirsin.';
    }
    if (!_disposed) notifyListeners();
    return permissionGranted;
  }

  Future<void> apply(DayliSettings settings) {
    final snapshot = settings.copy();
    final work = _queue.then((_) async {
      if (disabled) return;
      try {
        await initialize();
        await _plugin.cancelAll();
        if (Platform.isAndroid) {
          permissionGranted =
              await _plugin
                  .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin
                  >()!
                  .areNotificationsEnabled() ??
              false;
        } else if (Platform.isIOS) {
          permissionGranted =
              (await _plugin
                      .resolvePlatformSpecificImplementation<
                        IOSFlutterLocalNotificationsPlugin
                      >()!
                      .checkPermissions())
                  ?.isEnabled ??
              false;
        }
        error = null;
        if (!snapshot.notifications) return;
        if (!permissionGranted) {
          error = 'Cihazda bildirim izni kapalı. Hatırlatmalar gönderilemiyor.';
          return;
        }
        final zone = await FlutterTimezone.getLocalTimezone();
        final location = tz.getLocation(zone.identifier);
        tz.setLocalLocation(location);
        for (final reminder in reminderPlan(snapshot)) {
          await _plugin.zonedSchedule(
            id: reminder.id,
            title: 'Rutin Defterim · ${reminder.title}',
            body: reminder.body,
            scheduledDate: nextReminder(
              location,
              DateTime.now(),
              reminder.minute,
            ),
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'dayli_reminders',
                'Rutin Defterim hatırlatmaları',
                channelDescription: 'Su, görev ve alışkanlık hatırlatmaları',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
                icon: 'ic_notification',
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentSound: true,
                presentBadge: false,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: reminder.tab.toString(),
          );
        }
      } catch (_) {
        error =
            'Hatırlatmalar planlanamadı. Ayarlardan yeniden deneyebilirsin.';
        try {
          await _plugin.cancelAll();
        } catch (_) {}
      } finally {
        if (!_disposed) notifyListeners();
      }
    });
    _queue = work.catchError((Object _) {});
    return work;
  }

  Future<void> openSettings() async {
    try {
      await _plugin.openAppNotificationSettings();
    } catch (_) {
      error = 'Cihaz ayarlarından Rutin Defterim bildirim izinlerini açabilirsin.';
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    requestedTab.dispose();
    super.dispose();
  }
}
