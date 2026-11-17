import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayli/data/dayli_store.dart';
import 'package:dayli/data/local_storage.dart';
import 'package:dayli/data/models.dart';

void main() {
  late DateTime now;
  late DayliStore store;
  setUp(() async {
    now = DateTime(2026, 9, 14, 10);
    store = DayliStore(LocalStorage.memory(), clock: () => now);
    await store.load();
  });
  tearDown(() => store.dispose());

  test(
    'Spor diskte korunur, düzenlenir, kaldırılır ve ilerlemeye yansır',
    () async {
      final directory = await Directory.systemTemp.createTemp('dayli-sport-');
      addTearDown(() => directory.delete(recursive: true));
      final first = DayliStore(LocalStorage(directory), clock: () => now);
      await first.load();
      await first.saveSport(done: true, minutes: 35, type: 'Yürüyüş');
      first.dispose();
      final reopened = DayliStore(LocalStorage(directory), clock: () => now);
      await reopened.load();
      expect(reopened.record.sport, true);
      expect(reopened.record.sportMinutes, 35);
      expect(reopened.record.sportType, 'Yürüyüş');
      expect(reopened.sportDays, 1);
      expect(reopened.dailyProgress(reopened.today), .5);
      await reopened.saveSport(done: true, minutes: 45, type: 'Yoga');
      expect(reopened.record.sportMinutes, 45);
      expect(reopened.record.sportType, 'Yoga');
      await reopened.saveSport(done: false, minutes: 0);
      reopened.dispose();
      final cleared = DayliStore(LocalStorage(directory), clock: () => now);
      await cleared.load();
      expect(cleared.record.sport, false);
      expect(cleared.record.sportMinutes, 0);
      expect(cleared.record.sportType, '');
      expect(cleared.sportDays, 0);
      expect(cleared.dailyProgress(cleared.today), 0);
      cleared.dispose();
    },
  );
  test('Görev ekleme, düzenleme, tamamlama ve silme', () async {
    await store.saveTask(
      name: 'Kitap oku',
      category: 'Kişisel',
      minute: 1200,
      note: '20 sayfa',
    );
    final id = store.tasks.single.id;
    await store.toggleTask(id);
    expect(store.taskRate(store.today), 1);
    await store.saveTask(id: id, name: 'Kitabı bitir');
    expect(store.tasks.single.name, 'Kitabı bitir');
    await store.toggleTask(id);
    expect(store.tasks.single.done, false);
    await store.deleteTask(id);
    expect(store.tasks, isEmpty);
  });
  test('Geçersiz girdiler kayıtları değiştirmez', () async {
    await expectLater(store.saveTask(name: ' '), throwsFormatException);
    await expectLater(store.saveHabit(name: ''), throwsFormatException);
    await expectLater(store.saveTask(name: 'x' * 81), throwsFormatException);
    await expectLater(
      store.saveSport(done: true, minutes: -1),
      throwsFormatException,
    );
    expect(store.tasks, isEmpty);
    expect(() => parseDay('2026-02-31'), throwsFormatException);
  });
  test('Su artar, azaltılır, sıfırın altına düşmez', () async {
    await store.changeWater(250);
    await store.changeWater(500);
    expect(store.record.water, 750);
    await store.changeWater(-250);
    expect(store.record.water, 500);
    await store.changeWater(-1000);
    expect(store.record.water, 0);
  });
  test('İlerleme dört alanı eşit ağırlıkla hesaplar', () async {
    await store.saveTask(name: 'Görev');
    await store.saveHabit(name: 'Almanca');
    await store.toggleTask(store.tasks.single.id);
    await store.changeWater(1000);
    await store.saveSport(done: true, minutes: 35);
    expect(store.dailyProgress(store.today), .625);
    await store.toggleHabit(store.habits.single.id);
    await store.changeWater(1000);
    expect(store.dailyProgress(store.today), 1);
    await store.changeWater(500);
    expect(store.dailyProgress(store.today), 1);
  });
  test('Gün değişimi ve kaçırılmış günler geçmişi korur', () async {
    await store.saveTask(name: 'Görev');
    await store.toggleTask(store.tasks.single.id);
    await store.saveHabit(name: 'Kitap', target: 2);
    final id = store.habits.single.id;
    await store.incrementHabit(id, 1);
    expect(store.record.habitDone(id), false);
    await store.incrementHabit(id, 1);
    await store.changeWater(2000);
    await store.saveSport(done: true, minutes: 35);
    final old = store.today;
    now = DateTime(2026, 9, 17, 0, 1);
    await store.refreshDay();
    expect(store.tasks, isEmpty);
    expect(store.record.water, 0);
    expect(store.record.sport, false);
    expect(store.record.habitDone(id), false);
    expect(store.data.days[old]!.water, 2000);
    expect(store.data.days.length, 4);
    expect(store.waterSuccessDays, 1);
    expect(store.sportDays, 1);
    expect(store.currentStreak(id), 0);
    expect(store.longestStreak(id), 1);
  });
  test(
    'Seri bugün tamamlanmasa da dün üzerinden sürer ve boş günde kırılır',
    () async {
      await store.saveHabit(name: 'Yürüyüş');
      final id = store.habits.single.id;
      await store.toggleHabit(id);
      now = DateTime(2026, 9, 15);
      await store.refreshDay();
      expect(store.currentStreak(id), 1);
      await store.toggleHabit(id);
      expect(store.currentStreak(id), 2);
      now = DateTime(2026, 9, 16);
      await store.refreshDay();
      expect(store.currentStreak(id), 2);
      now = DateTime(2026, 9, 17);
      await store.refreshDay();
      expect(store.currentStreak(id), 0);
      expect(store.bestStreak, 2);
      await store.deleteHabit(id);
      expect(store.habits, isEmpty);
      expect(store.bestStreak, 2);
    },
  );
  test('Su hedefi geçmiş günün hedefini değiştirmez', () async {
    now = DateTime(2026, 9, 15);
    await store.refreshDay();
    final settings = store.settings.copy()..waterGoal = 3000;
    await store.saveSettings(settings);
    expect(store.data.days['2026-09-14']!.waterGoal, 2000);
    expect(store.record.waterGoal, 3000);
  });
  test('Eşzamanlı eklemeler kaybolmaz ve yeniden açılışta kalır', () async {
    await Future.wait(List.generate(8, (_) => store.changeWater(250)));
    final reopened = DayliStore(store.storage, clock: () => now);
    await reopened.load();
    expect(reopened.record.water, 2000);
    reopened.dispose();
  });
  test('Yazma hatası değişikliği geri alır ve sonraki kayıt çalışır', () async {
    final storage = _FailingStorage();
    final subject = DayliStore(storage, clock: () => now);
    await subject.load();
    storage.fail = true;
    await expectLater(
      subject.changeWater(250),
      throwsA(isA<FileSystemException>()),
    );
    expect(subject.record.water, 0);
    storage.fail = false;
    await subject.changeWater(500);
    expect(subject.record.water, 500);
    subject.dispose();
  });
  test('Alışkanlık hedefi düzenlenince eski gün ve seri korunur', () async {
    await store.saveHabit(name: 'Kitap', target: 2);
    final id = store.habits.single.id;
    await store.toggleHabit(id);
    now = DateTime(2026, 9, 15);
    await store.refreshDay();
    await store.saveHabit(id: id, name: 'Kitap oku', target: 3);
    expect(store.data.days['2026-09-14']!.habitTargets[id], 2);
    expect(store.record.habitTargets[id], 3);
    expect(store.currentStreak(id), 1);
  });
  test('Disk kaydı, yedekten kurtarma ve bozuk dosyaları koruma', () async {
    final directory = await Directory.systemTemp.createTemp('dayli-test-');
    addTearDown(() => directory.delete(recursive: true));
    final storage = LocalStorage(directory);
    final diskStore = DayliStore(storage, clock: () => now);
    await diskStore.load();
    await diskStore.saveTask(name: 'Kalıcı görev');
    await diskStore.changeWater(250);
    final reopened = DayliStore(storage, clock: () => now);
    await reopened.load();
    expect(reopened.tasks.single.name, 'Kalıcı görev');
    expect(reopened.record.water, 250);
    await File('${directory.path}/dayli.json').writeAsString('bozuk');
    final recovered = await storage.load();
    expect(recovered!.tasks.single.name, 'Kalıcı görev');
    expect(storage.recoveryMessage, isNotNull);
    await File('${directory.path}/dayli.json').writeAsString('bozuk');
    await File('${directory.path}/dayli.backup.json').writeAsString('bozuk');
    await expectLater(storage.load(), throwsA(isA<FileSystemException>()));
    expect(await File('${directory.path}/dayli.json').readAsString(), 'bozuk');
    diskStore.dispose();
    reopened.dispose();
  });
}

class _FailingStorage extends LocalStorage {
  _FailingStorage() : super.memory();
  bool fail = false;
  @override
  Future<void> save(DayliData data) async {
    if (fail) throw const FileSystemException('Disk dolu');
    await super.save(data);
  }
}
