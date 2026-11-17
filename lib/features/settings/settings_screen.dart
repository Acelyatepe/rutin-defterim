import 'package:flutter/material.dart';
import '../../app/dayli_scope.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/widgets/form_helpers.dart';
import '../../data/models.dart';
import 'support_ad_card.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;
  Future<void> _update(
    void Function(DayliSettings) edit, {
    bool schedule = false,
    bool request = false,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    final store = DayliScope.of(context);
    final reminders = DayliScope.reminders(context);
    if (request && !await reminders.requestPermission()) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    final next = store.settings.copy();
    edit(next);
    if (!mounted) return;
    final success = await performAction(
      context,
      () => store.saveSettings(next),
    );
    if (success && schedule) await reminders.apply(next);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final store = DayliScope.of(context);
    final s = store.settings;
    final reminders = DayliScope.reminders(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: SafeArea(
        child: PageLayout(
          children: [
            const SectionHeading('Görünüm'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: DropdownButtonFormField<ThemeMode>(
                  key: ValueKey(s.theme),
                  initialValue: s.theme,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Tema'),
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Açık'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Koyu'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('Sistem'),
                    ),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) {
                          if (v != null) _update((s) => s.theme = v);
                        },
                ),
              ),
            ),
            const SectionHeading('Günlük hedef'),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(20),
                leading: const Icon(Icons.water_drop_outlined),
                title: const Text('Su hedefi'),
                subtitle: Text('${s.waterGoal} ml · Bugün ve sonraki günler'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _busy
                    ? null
                    : () async {
                        final value = await showDayliSheet<int>(
                          context,
                          _WaterGoalEditor(goal: s.waterGoal),
                        );
                        if (value != null && mounted) {
                          await _update((s) => s.waterGoal = value);
                        }
                      },
              ),
            ),
            const SectionHeading('Hatırlatmalar'),
            Card(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    title: const Text('Bildirimler'),
                    subtitle: const Text('İzin yalnızca açtığında istenir.'),
                    value: s.notifications,
                    onChanged: _busy
                        ? null
                        : (v) => _update(
                            (s) => s.notifications = v,
                            schedule: true,
                            request: v,
                          ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    title: const Text('Su hatırlatmaları'),
                    subtitle: const Text('08:00–20:00 arası, iki saatte bir'),
                    value: s.waterReminder,
                    onChanged: !s.notifications || _busy
                        ? null
                        : (v) => _update(
                            (s) => s.waterReminder = v,
                            schedule: true,
                          ),
                  ),
                  SwitchListTile.adaptive(
                    title: const Text('Görev hatırlatması'),
                    subtitle: const Text('Her gün 20:00'),
                    value: s.taskReminder,
                    onChanged: !s.notifications || _busy
                        ? null
                        : (v) => _update(
                            (s) => s.taskReminder = v,
                            schedule: true,
                          ),
                  ),
                  SwitchListTile.adaptive(
                    title: const Text('Alışkanlık hatırlatması'),
                    subtitle: Text('Her gün ${clockLabel(s.habitMinute)}'),
                    value: s.habitReminder,
                    onChanged: !s.notifications || _busy
                        ? null
                        : (v) => _update(
                            (s) => s.habitReminder = v,
                            schedule: true,
                          ),
                  ),
                  ListTile(
                    title: const Text('Alışkanlık saati'),
                    subtitle: Text(clockLabel(s.habitMinute)),
                    trailing: const Icon(Icons.schedule_rounded),
                    enabled: s.notifications && s.habitReminder && !_busy,
                    onTap: !s.notifications || !s.habitReminder || _busy
                        ? null
                        : () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: s.habitMinute ~/ 60,
                                minute: s.habitMinute % 60,
                              ),
                            );
                            if (time != null && mounted) {
                              await _update(
                                (s) => s.habitMinute =
                                    time.hour * 60 + time.minute,
                                schedule: true,
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
            ListenableBuilder(
              listenable: reminders,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (reminders.error != null) ...[
                    const SizedBox(height: 12),
                    Text(reminders.error!),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: _busy ? null : reminders.openSettings,
                          child: const Text('Cihaz bildirim ayarları'),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _update((_) {}, schedule: true),
                          child: const Text('Tekrar dene'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Hatırlatmalar cihazında çalışır. Pil tasarrufu ve cihaz ayarları nedeniyle saatler biraz gecikebilir. Saat dilimi uygulamaya döndüğünde yenilenir.',
            ),
            const SectionHeading('Rutin Defterim’i Destekle'),
            const SupportAdCard(),
            const SectionHeading('Rutin Defterim hakkında'),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rutin Defterim · 1.0.0',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Küçük adımlar, güzel günler.\nGünlük planlama ve alışkanlık takibi.',
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Görev, alışkanlık, su ve spor kayıtların cihazında yerel olarak saklanır ve reklam hizmetine gönderilmez. Planlama özellikleri internet olmadan çalışır. İsteğe bağlı destek reklamları Google AdMob tarafından sunulur; reklam ve izin hizmetleri cihaz, bağlantı ve reklam etkileşimi verilerini işleyebilir ve sunucularına aktarabilir. Reklamlar internet gerektirir. Gizlilik tercihlerini destek bölümünden yönetebilirsin. Uygulamayı kaldırmak yerel kayıtları siler. Bulut yedeklemesi ve dışa aktarma bulunmaz.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Gizlilik Politikası'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterGoalEditor extends StatefulWidget {
  const _WaterGoalEditor({required this.goal});
  final int goal;
  @override
  State<_WaterGoalEditor> createState() => _WaterGoalEditorState();
}

class _WaterGoalEditorState extends State<_WaterGoalEditor> {
  final _form = GlobalKey<FormState>();
  late final _value = TextEditingController(text: '${widget.goal}');
  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: FormBody(
      children: [
        Text(
          'Günlük su hedefi',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _value,
          autofocus: true,
          maxLength: 5,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Hedef (ml)'),
          validator: (v) {
            final n = int.tryParse(v ?? '');
            return n == null || n < 250 || n > 10000
                ? '250–10000 ml arasında bir hedef yaz.'
                : null;
          },
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, int.parse(_value.text));
            }
          },
          child: const Text('Hedefi kaydet'),
        ),
      ],
    ),
  );
}
