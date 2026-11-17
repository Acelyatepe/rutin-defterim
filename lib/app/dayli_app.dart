import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/notifications.dart';
import '../core/theme/dayli_theme.dart';
import '../data/dayli_store.dart';
import '../data/local_storage.dart';
import 'dayli_scope.dart';
import 'dayli_shell.dart';

class DayliApp extends StatefulWidget {
  const DayliApp({super.key, this.store, this.notifications});
  final DayliStore? store;
  final DayliNotifications? notifications;
  @override
  State<DayliApp> createState() => _DayliAppState();
}

class _DayliAppState extends State<DayliApp> with WidgetsBindingObserver {
  DayliStore? _store;
  late final DayliNotifications _notifications;
  Timer? _timer;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notifications = widget.notifications ?? DayliNotifications();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    DayliStore? store;
    try {
      store = widget.store ?? DayliStore(await LocalStorage.open());
      if (widget.store == null) await store.load();
      if (!mounted) {
        if (widget.store == null) store.dispose();
        return;
      }
      _store = store;
      _store!.addListener(_rebuild);
      _timer = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
      setState(() => _loading = false);
      unawaited(_notifications.apply(store.settings));
    } catch (_) {
      if (widget.store == null) store?.dispose();
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Yerel veriler açılamadı. Dosyaların korunuyor. Cihazında boş alan olduğundan emin olup tekrar dene.';
        });
      }
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _refresh({bool reminders = false}) async {
    if (_store == null) return;
    try {
      await _store?.refreshDay();
      if (mounted) setState(() => _error = null);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Yeni gün kaydı açılamadı. Cihazında boş alan olduğundan emin olup tekrar dene.',
        );
      }
    }
    if (reminders && _store != null) {
      await _notifications.apply(_store!.settings);
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh(reminders: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _store?.removeListener(_rebuild);
    if (widget.store == null) _store?.dispose();
    if (widget.notifications == null) _notifications.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (_loading || _store == null) {
      // Açılış ekranı: görselin kendi içinde isim ve slogan olduğu için
      // ayrıca yazı eklenmez. Görsel ekranı tamamen kaplar.
      home = Scaffold(
        backgroundColor: const Color(0xFFF9F9F2),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/branding/rutin-defterim-splash.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              semanticLabel: 'Rutin Defterim',
            ),
            if (!_loading)
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error ?? '', textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _load,
                              child: const Text('Tekrar dene'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      home = DayliScope(
        store: _store!,
        notifications: _notifications,
        child: DayliShell(error: _error, onRetry: _refresh),
      );
    }
    return MaterialApp(
      title: 'Rutin Defterim',
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: DayliTheme.light,
      darkTheme: DayliTheme.dark,
      themeMode: _store?.settings.theme ?? ThemeMode.light,
      builder: (context, child) => _store == null
          ? child!
          : DayliScope(
              store: _store!,
              notifications: _notifications,
              child: child!,
            ),
      home: home,
    );
  }
}