import 'package:flutter/material.dart';

String dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
DateTime parseDay(String key) {
  final date = DateTime.tryParse(key);
  if (date == null ||
      dayKey(date) != key ||
      date.year < 2000 ||
      date.year > 2200) {
    throw const FormatException('Geçersiz tarih');
  }
  return date;
}

String previousDay(String key) {
  final d = parseDay(key);
  return dayKey(DateTime(d.year, d.month, d.day - 1));
}

int boundedInt(dynamic value, int min, int max) {
  if (value is! int || value < min || value > max) {
    throw const FormatException('Geçersiz sayı');
  }
  return value;
}

String validText(dynamic value, int max, {bool required = false}) {
  if (value is! String ||
      value.length > max ||
      (required && value.trim().isEmpty)) {
    throw const FormatException('Geçersiz metin');
  }
  return value.trim();
}

class DayTask {
  DayTask({
    required this.id,
    required this.date,
    required this.name,
    this.category = '',
    this.minute,
    this.note = '',
    this.done = false,
  });
  final String id;
  final String date;
  String name;
  String category;
  int? minute;
  String note;
  bool done;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'name': name,
    'category': category,
    'minute': minute,
    'note': note,
    'done': done,
  };
  factory DayTask.fromJson(Map<String, dynamic> j) {
    parseDay(j['date'] as String);
    return DayTask(
      id: validText(j['id'], 100, required: true),
      date: j['date'],
      name: validText(j['name'], 80, required: true),
      category: validText(j['category'], 30),
      minute: j['minute'] == null ? null : boundedInt(j['minute'], 0, 1439),
      note: validText(j['note'], 500),
      done: j['done'] as bool,
    );
  }
}

class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.createdOn,
    this.deletedOn,
    this.target = 1,
    this.icon = 0,
    this.color = 0,
  });
  final String id;
  String name;
  final String createdOn;
  String? deletedOn;
  int target;
  int icon;
  int color;
  bool activeOn(String day) =>
      createdOn.compareTo(day) <= 0 &&
      (deletedOn == null || deletedOn!.compareTo(day) > 0);
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdOn': createdOn,
    'deletedOn': deletedOn,
    'target': target,
    'icon': icon,
    'color': color,
  };
  factory Habit.fromJson(Map<String, dynamic> j) {
    parseDay(j['createdOn'] as String);
    if (j['deletedOn'] != null) parseDay(j['deletedOn'] as String);
    return Habit(
      id: validText(j['id'], 100, required: true),
      name: validText(j['name'], 60, required: true),
      createdOn: j['createdOn'],
      deletedOn: j['deletedOn'] as String?,
      target: boundedInt(j['target'], 1, 100),
      icon: boundedInt(j['icon'], 0, 5),
      color: boundedInt(j['color'], 0, 3),
    );
  }
}

class DayRecord {
  DayRecord({
    this.water = 0,
    required this.waterGoal,
    this.sport = false,
    this.sportMinutes = 0,
    this.sportType = '',
    Map<String, int>? habitTargets,
    Map<String, int>? habitCounts,
  }) : habitTargets = habitTargets ?? {},
       habitCounts = habitCounts ?? {};
  int water;
  int waterGoal;
  bool sport;
  int sportMinutes;
  String sportType;
  final Map<String, int> habitTargets;
  final Map<String, int> habitCounts;
  bool habitDone(String id) =>
      habitTargets.containsKey(id) &&
      (habitCounts[id] ?? 0) >= habitTargets[id]!;
  Map<String, dynamic> toJson() => {
    'water': water,
    'waterGoal': waterGoal,
    'sport': sport,
    'sportMinutes': sportMinutes,
    'sportType': sportType,
    'habitTargets': habitTargets,
    'habitCounts': habitCounts,
  };
  factory DayRecord.fromJson(Map<String, dynamic> j) => DayRecord(
    water: boundedInt(j['water'], 0, 100000),
    waterGoal: boundedInt(j['waterGoal'], 250, 10000),
    sport: j['sport'] as bool,
    sportMinutes: boundedInt(j['sportMinutes'], 0, 1440),
    sportType: validText(j['sportType'], 30),
    habitTargets: (j['habitTargets'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, boundedInt(v, 1, 100)),
    ),
    habitCounts: (j['habitCounts'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, boundedInt(v, 0, 100)),
    ),
  );
}

class DayliSettings {
  DayliSettings({
    this.theme = ThemeMode.light,
    this.waterGoal = 2000,
    this.notifications = false,
    this.waterReminder = true,
    this.taskReminder = true,
    this.habitReminder = true,
    this.habitMinute = 19 * 60,
  });
  ThemeMode theme;
  int waterGoal;
  bool notifications;
  bool waterReminder;
  bool taskReminder;
  bool habitReminder;
  int habitMinute;
  Map<String, dynamic> toJson() => {
    'theme': theme.name,
    'waterGoal': waterGoal,
    'notifications': notifications,
    'waterReminder': waterReminder,
    'taskReminder': taskReminder,
    'habitReminder': habitReminder,
    'habitMinute': habitMinute,
  };
  factory DayliSettings.fromJson(Map<String, dynamic> j) => DayliSettings(
    theme: ThemeMode.values.byName(j['theme'] as String),
    waterGoal: boundedInt(j['waterGoal'], 250, 10000),
    notifications: j['notifications'] as bool,
    waterReminder: j['waterReminder'] as bool,
    taskReminder: j['taskReminder'] as bool,
    habitReminder: j['habitReminder'] as bool,
    habitMinute: boundedInt(j['habitMinute'], 0, 1439),
  );
  DayliSettings copy() => DayliSettings.fromJson(toJson());
}

class DayliData {
  DayliData({
    required this.startedOn,
    DayliSettings? settings,
    List<DayTask>? tasks,
    List<Habit>? habits,
    Map<String, DayRecord>? days,
  }) : settings = settings ?? DayliSettings(),
       tasks = tasks ?? [],
       habits = habits ?? [],
       days = days ?? {};
  final String startedOn;
  DayliSettings settings;
  final List<DayTask> tasks;
  final List<Habit> habits;
  final Map<String, DayRecord> days;
  Map<String, dynamic> toJson() => {
    'version': 1,
    'startedOn': startedOn,
    'settings': settings.toJson(),
    'tasks': tasks.map((e) => e.toJson()).toList(),
    'habits': habits.map((e) => e.toJson()).toList(),
    'days': days.map((k, v) => MapEntry(k, v.toJson())),
  };
  factory DayliData.fromJson(Map<String, dynamic> j) {
    if (j['version'] != 1) {
      throw const FormatException('Desteklenmeyen veri sürümü');
    }
    parseDay(j['startedOn'] as String);
    final data = DayliData(
      startedOn: j['startedOn'],
      settings: DayliSettings.fromJson(j['settings']),
      tasks: (j['tasks'] as List).map((e) => DayTask.fromJson(e)).toList(),
      habits: (j['habits'] as List).map((e) => Habit.fromJson(e)).toList(),
      days: (j['days'] as Map<String, dynamic>).map((k, v) {
        parseDay(k);
        return MapEntry(k, DayRecord.fromJson(v));
      }),
    );
    if (data.tasks.map((t) => t.id).toSet().length != data.tasks.length ||
        data.habits.map((h) => h.id).toSet().length != data.habits.length) {
      throw const FormatException('Tekrarlanan kayıt');
    }
    return data;
  }
}
