import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayli/app/dayli_app.dart';
import 'package:dayli/core/notifications.dart';
import 'package:dayli/data/dayli_store.dart';
import 'package:dayli/data/local_storage.dart';

Future<DayliStore> mount(
  WidgetTester tester, {
  ThemeMode mode = ThemeMode.light,
}) async {
  final store = DayliStore(
    LocalStorage.memory(),
    clock: () => DateTime(2026, 9, 14, 10),
  );
  await store.load();
  await store.saveSettings(store.settings.copy()..theme = mode);
  final reminders = DayliNotifications(disabled: true);
  addTearDown(store.dispose);
  addTearDown(reminders.dispose);
  await tester.pumpWidget(DayliApp(store: store, notifications: reminders));
  await tester.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('Spor formu süre girişi, kaydetme, düzenleme ve kaldırma', (
    tester,
  ) async {
    final store = await mount(tester);
    await tester.ensureVisible(find.text('Spor kaydı ekle'));
    await tester.tap(find.text('Spor kaydı ekle'));
    await tester.pumpAndSettle();
    final field = find.widgetWithText(TextFormField, 'Süre (dakika)');
    expect(tester.widget<TextFormField>(field).enabled, true);
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('1–1440 arasında dakika yaz.'), findsOneWidget);
    await tester.enterText(field, '35');
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(store.record.sport, true);
    expect(find.text('35 dakika'), findsOneWidget);
    await tester.ensureVisible(find.text('Spor kaydını düzenle'));
    await tester.tap(find.text('Spor kaydını düzenle'));
    await tester.pumpAndSettle();
    await tester.enterText(field, '45');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yoga').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(store.record.sportMinutes, 45);
    expect(store.record.sportType, 'Yoga');
    await tester.tap(find.text('Spor kaydını düzenle'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Kaydı kaldır'));
    await tester.tap(find.text('Kaydı kaldır'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    expect(store.record.sport, false);
    expect(store.record.sportMinutes, 0);
    expect(find.text('Spor kaydı ekle'), findsOneWidget);
  });

  testWidgets('Sekmeler arasında görev durumu korunur', (tester) async {
    final store = await mount(tester);
    expect(find.text('Günaydın.'), findsOneWidget);
    await store.saveTask(name: 'Kitap oku');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Checkbox).first);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(store.tasks.single.done, true);
    await tester.tap(find.text('Alışkanlıklar'));
    await tester.pumpAndSettle();
    expect(find.text('Küçük adımlar, her gün.'), findsOneWidget);
    await tester.tap(find.text('İlerleme'));
    await tester.pumpAndSettle();
    expect(find.text('Her adım bir ilerleme.'), findsOneWidget);
    await tester.tap(find.text('Bugün'));
    await tester.pumpAndSettle();
    expect(store.tasks.single.done, true);
  });
  testWidgets('Hızlı görev boş girdiyi reddeder ve geçerli görevi ekler', (
    tester,
  ) async {
    final store = await mount(tester);
    await tester.ensureVisible(find.text('Hızlı görev ekle'));
    await tester.tap(find.text('Hızlı görev ekle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Görevi ekle'));
    await tester.pumpAndSettle();
    expect(find.text('Bir görev adı yaz.'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Görev adı'),
      'Çiçekleri sula',
    );
    await tester.tap(find.text('Görevi ekle'));
    await tester.pumpAndSettle();
    expect(store.tasks.single.name, 'Çiçekleri sula');
  });
  testWidgets('Alışkanlık ekleme, tamamlama ve su artırma', (tester) async {
    final store = await mount(tester);
    await tester.ensureVisible(find.text('+250 ml'));
    await tester.tap(find.text('+250 ml'));
    await tester.pumpAndSettle();
    expect(store.record.water, 250);
    await tester.tap(find.text('Alışkanlıklar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Alışkanlık ekle'));
    await tester.tap(find.text('Alışkanlık ekle'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Alışkanlık adı'),
      'Almanca çalış',
    );
    await tester.ensureVisible(find.text('Alışkanlığı ekle'));
    await tester.tap(find.text('Alışkanlığı ekle'));
    await tester.pumpAndSettle();
    expect(store.habits.single.name, 'Almanca çalış');
    await tester.ensureVisible(find.text('Bugün tamamla'));
    await tester.tap(find.text('Bugün tamamla'));
    await tester.pumpAndSettle();
    expect(store.record.habitDone(store.habits.single.id), true);
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('$size $mode büyük yazıda taşmaz', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.8;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final store = await mount(tester, mode: mode);
        await store.saveTask(name: 'Uzun görev adı ' * 5, note: 'Not ' * 100);
        await store.saveHabit(name: 'Günlük alışkanlık ' * 3, target: 10);
        await tester.pumpAndSettle();
        for (final tab in ['Alışkanlıklar', 'İlerleme', 'Bugün']) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.tap(find.byTooltip('Ayarlar'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('Dar ekranda klavyeli görev formu taşmaz', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await mount(tester);
    await tester.ensureVisible(find.text('Hızlı görev ekle'));
    await tester.tap(find.text('Hızlı görev ekle'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Görev adı'),
      'Yeni görev',
    );
    await tester.ensureVisible(find.text('Görevi ekle'));
    await tester.tap(find.text('Görevi ekle'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
