import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'local_storage.dart';
import 'models.dart';

class DayliStore extends ChangeNotifier {
  DayliStore(this.storage, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final LocalStorage storage;
  final DateTime Function() clock;
  late DayliData _data;
  late String today;
  Future<void> _queue = Future.value();
  bool _disposed = false;
  String? message;
  DayliData get data => _data;
  DayliSettings get settings => _data.settings;
  DayRecord get record => _data.days[today]!;
  List<DayTask> get tasks => _data.tasks.where((t) => t.date == today).toList();
  List<Habit> get habits =>
      _data.habits.where((h) => h.activeOn(today)).toList();

  Future<void> load() async {
    _data = await storage.load() ?? DayliData(startedOn: dayKey(clock()));
    today = dayKey(clock());
    _ensureDays();
    await storage.save(_data);
    message = storage.recoveryMessage;
  }

  void _ensureDays() {
    today = dayKey(clock());
    parseDay(today);
    final keys = _data.days.keys.where((k) => k.compareTo(today) <= 0).toList()
      ..sort();
    var cursor = parseDay(keys.isEmpty ? today : keys.last);
    final end = parseDay(today);
    while (!cursor.isAfter(end)) {
      final key = dayKey(cursor);
      _data.days.putIfAbsent(
        key,
        () => DayRecord(
          waterGoal: settings.waterGoal,
          habitTargets: {
            for (final h in _data.habits.where((h) => h.activeOn(key)))
              h.id: h.target,
          },
        ),
      );
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }
  }

  Future<void> _change(void Function() edit) {
    final operation = _queue.then((_) async {
      final before = DayliData.fromJson(_data.toJson());
      final oldToday = today;
      try {
        _ensureDays();
        edit();
        await storage.save(_data);
        message = null;
      } catch (_) {
        _data = before;
        today = oldToday;
        rethrow;
      }
      if (!_disposed) notifyListeners();
    });
    _queue = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> refreshDay() async {
    if (dayKey(clock()) != today) await _change(() {});
  }

  String _id() =>
      '${clock().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';

  Future<void> saveTask({
    String? id,
    required String name,
    String category = '',
    int? minute,
    String note = '',
  }) => _change(() {
    name = validText(name, 80, required: true);
    category = validText(category, 30);
    note = validText(note, 500);
    if (minute != null) boundedInt(minute, 0, 1439);
    if (id == null) {
      _data.tasks.add(
        DayTask(
          id: _id(),
          date: today,
          name: name,
          category: category,
          minute: minute,
          note: note,
        ),
      );
    } else {
      final t = _data.tasks.firstWhere((t) => t.id == id);
      t.name = name;
      t.category = category;
      t.minute = minute;
      t.note = note;
    }
  });
  Future<void> toggleTask(String id) => _change(() {
    final t = _data.tasks.firstWhere((t) => t.id == id);
    t.done = !t.done;
  });
  Future<void> deleteTask(String id) =>
      _change(() => _data.tasks.removeWhere((t) => t.id == id));

  Future<void> changeWater(int amount, {String? date}) => _change(() {
    if (amount.abs() > 10000) {
      throw const FormatException('Miktar en fazla 10000 ml olabilir.');
    }
    final target = _data.days[date ?? today];
    if (target == null) throw const FormatException('Gün kaydı bulunamadı.');
    target.water = (target.water + amount).clamp(0, 100000);
  });
  Future<void> saveSport({
    required bool done,
    required int minutes,
    String type = '',
  }) => _change(() {
    boundedInt(minutes, 0, 1440);
    if (![
      '',
      'Yürüyüş',
      'Koşu',
      'Spor salonu',
      'Yoga',
      'Diğer',
    ].contains(type)) {
      throw const FormatException('Geçersiz spor türü');
    }
    record.sport = done;
    record.sportMinutes = done ? minutes : 0;
    record.sportType = done ? type : '';
  });
  Future<void> saveHabit({
    String? id,
    required String name,
    int target = 1,
    int icon = 0,
    int color = 0,
  }) => _change(() {
    name = validText(name, 60, required: true);
    boundedInt(target, 1, 100);
    boundedInt(icon, 0, 5);
    boundedInt(color, 0, 3);
    if (id == null) {
      final h = Habit(
        id: _id(),
        name: name,
        createdOn: today,
        target: target,
        icon: icon,
        color: color,
      );
      _data.habits.add(h);
      record.habitTargets[h.id] = target;
    } else {
      final h = _data.habits.firstWhere((h) => h.id == id);
      h.name = name;
      h.target = target;
      h.icon = icon;
      h.color = color;
      record.habitTargets[id] = target;
      record.habitCounts[id] = (record.habitCounts[id] ?? 0).clamp(0, target);
    }
  });
  Future<void> deleteHabit(String id) => _change(() {
    _data.habits.firstWhere((h) => h.id == id).deletedOn = today;
    record.habitTargets.remove(id);
    record.habitCounts.remove(id);
  });
  Future<void> toggleHabit(String id) => _change(() {
    final target = record.habitTargets[id];
    if (target == null) throw const FormatException('Alışkanlık bulunamadı.');
    record.habitCounts[id] = record.habitDone(id) ? 0 : target;
  });
  Future<void> incrementHabit(String id, int amount) => _change(() {
    final target = record.habitTargets[id];
    if (target == null) throw const FormatException('Alışkanlık bulunamadı.');
    record.habitCounts[id] = ((record.habitCounts[id] ?? 0) + amount).clamp(
      0,
      target,
    );
  });
  Future<void> saveSettings(DayliSettings value) => _change(() {
    _data.settings = DayliSettings.fromJson(value.toJson());
    record.waterGoal = value.waterGoal;
  });

  double taskRate(String day) {
    final list = _data.tasks.where((t) => t.date == day).toList();
    return list.isEmpty ? 0 : list.where((t) => t.done).length / list.length;
  }

  double habitRate(String day) {
    final r = _data.days[day];
    if (r == null || r.habitTargets.isEmpty) return 0;
    return r.habitTargets.keys.where(r.habitDone).length /
        r.habitTargets.length;
  }

  double dailyProgress(String day) {
    final r = _data.days[day];
    if (r == null) return 0;
    final parts = <double>[
      (r.water / r.waterGoal).clamp(0, 1),
      r.sport ? 1 : 0,
    ];
    if (_data.tasks.any((t) => t.date == day)) parts.add(taskRate(day));
    if (r.habitTargets.isNotEmpty) parts.add(habitRate(day));
    return parts.reduce((a, b) => a + b) / parts.length;
  }

  List<String> get week {
    final d = parseDay(today);
    final monday = DateTime(d.year, d.month, d.day - d.weekday + 1);
    return List.generate(
      7,
      (i) => dayKey(DateTime(monday.year, monday.month, monday.day + i)),
    );
  }

  List<String> get elapsedWeek => week
      .where(
        (d) => d.compareTo(today) <= 0 && d.compareTo(_data.startedOn) >= 0,
      )
      .toList();
  double get weeklyTaskRate {
    final dates = elapsedWeek.toSet();
    final list = _data.tasks.where((t) => dates.contains(t.date)).toList();
    return list.isEmpty ? 0 : list.where((t) => t.done).length / list.length;
  }

  double get weeklyHabitRate {
    var total = 0;
    var done = 0;
    for (final d in elapsedWeek) {
      final r = _data.days[d];
      if (r == null) continue;
      total += r.habitTargets.length;
      done += r.habitTargets.keys.where(r.habitDone).length;
    }
    return total == 0 ? 0 : done / total;
  }

  int get waterSuccessDays => elapsedWeek.where((d) {
    final r = _data.days[d];
    return r != null && r.water >= r.waterGoal;
  }).length;
  int get sportDays =>
      elapsedWeek.where((d) => _data.days[d]?.sport == true).length;
  int currentStreak(String id) {
    var cursor = today;
    if (!(_data.days[cursor]?.habitDone(id) ?? false)) {
      cursor = previousDay(cursor);
    }
    var count = 0;
    while (_data.days[cursor]?.habitDone(id) ?? false) {
      count++;
      cursor = previousDay(cursor);
    }
    return count;
  }

  int longestStreak(String id) {
    final days =
        _data.days.keys
            .where(
              (d) => d.compareTo(today) <= 0 && _data.days[d]!.habitDone(id),
            )
            .toList()
          ..sort();
    var best = 0;
    var run = 0;
    String? last;
    for (final d in days) {
      run = last == previousDay(d) ? run + 1 : 1;
      best = max(best, run);
      last = d;
    }
    return best;
  }

  int get bestStreak =>
      _data.habits.fold(0, (best, h) => max(best, longestStreak(h.id)));

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
