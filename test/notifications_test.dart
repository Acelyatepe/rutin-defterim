import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:dayli/core/notifications.dart';
import 'package:dayli/data/models.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);
  test('Kapalı bildirimlerde plan yok, açıkken dokuz yerel hatırlatma var', () {
    final settings = DayliSettings();
    expect(reminderPlan(settings), isEmpty);
    settings.notifications = true;
    final plan = reminderPlan(settings);
    expect(plan.length, 9);
    expect(plan.map((r) => r.id).toSet().length, 9);
    expect(plan.where((r) => r.id < 200).map((r) => r.minute).toList(), [
      480,
      600,
      720,
      840,
      960,
      1080,
      1200,
    ]);
    settings.waterReminder = false;
    settings.taskReminder = false;
    settings.habitMinute = 1350;
    expect(reminderPlan(settings).single.minute, 1350);
  });
  test('Hatırlatma geçmişe planlanmaz ve yerel saat kullanır', () {
    final zone = tz.getLocation('Europe/Istanbul');
    final now = tz.TZDateTime(zone, 2026, 9, 14, 20, 1);
    final next = nextReminder(zone, now, 1200);
    expect(next.day, 15);
    expect(next.hour, 20);
    expect(next.minute, 0);
    expect(next.timeZoneOffset, const Duration(hours: 3));
  });
  test('Yaz saati geçişi saat kaydırmaz', () {
    final zone = tz.getLocation('Europe/Berlin');
    final now = tz.TZDateTime(zone, 2026, 3, 28, 21);
    final next = nextReminder(zone, now, 20 * 60);
    expect(next.day, 29);
    expect(next.hour, 20);
    expect(next.timeZoneOffset, const Duration(hours: 2));
  });
}
