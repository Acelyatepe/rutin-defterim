import 'package:flutter/material.dart';
import '../../app/dayli_scope.dart';
import '../../core/widgets/form_helpers.dart';
import '../../data/models.dart';

class SportCard extends StatelessWidget {
  const SportCard({super.key});
  @override
  Widget build(BuildContext context) {
    final r = DayliScope.of(context).record;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: dark ? const Color(0xFF3B3548) : const Color(0xFFEFEAF7),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_walk_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hareket zamanı',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              r.sport ? 'Bugün tamamlandı' : 'Kendine hareket alanı aç',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              r.sport
                  ? '${r.sportMinutes} dakika${r.sportType.isEmpty ? '' : ' · ${r.sportType}'}'
                  : 'Biraz hareket, taze bir zihin.',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => showDayliSheet(context, _SportEditor(record: r)),
              icon: Icon(r.sport ? Icons.edit_outlined : Icons.add_rounded),
              label: Text(r.sport ? 'Spor kaydını düzenle' : 'Spor kaydı ekle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SportEditor extends StatefulWidget {
  const _SportEditor({required this.record});
  final DayRecord record;
  @override
  State<_SportEditor> createState() => _SportEditorState();
}

class _SportEditorState extends State<_SportEditor> {
  final _form = GlobalKey<FormState>();
  late final _minutes = TextEditingController(
    text: widget.record.sportMinutes == 0
        ? ''
        : '${widget.record.sportMinutes}',
  );
  late String _type = widget.record.sportType;
  bool _busy = false;
  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: FormBody(
      children: [
        Text(
          'Bugünkü hareketin',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _minutes,
          enabled: !_busy,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(labelText: 'Süre (dakika)'),
          validator: (v) {
            final n = int.tryParse(v?.trim() ?? '');
            return n == null || n < 1 || n > 1440
                ? '1–1440 arasında dakika yaz.'
                : null;
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _type,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Spor türü'),
          items: [
            for (final t in [
              '',
              'Yürüyüş',
              'Koşu',
              'Spor salonu',
              'Yoga',
              'Diğer',
            ])
              DropdownMenuItem(
                value: t,
                child: Text(
                  t.isEmpty
                      ? 'Seçilmedi'
                      : t == 'Spor salonu'
                      ? 'Spor Salonu'
                      : t,
                ),
              ),
          ],
          onChanged: _busy ? null : (v) => setState(() => _type = v ?? ''),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy
              ? null
              : () async {
                  if (!_form.currentState!.validate()) return;
                  setState(() => _busy = true);
                  final store = DayliScope.of(context);
                  final success = await performAction(
                    context,
                    () => store.saveSport(
                      done: true,
                      minutes: int.parse(_minutes.text.trim()),
                      type: _type,
                    ),
                  );
                  if (!context.mounted) return;
                  if (success) {
                    Navigator.pop(context);
                  } else {
                    setState(() => _busy = false);
                  }
                },
          child: Text(_busy ? 'Kaydediliyor…' : 'Kaydet'),
        ),
        if (widget.record.sport)
          TextButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Kaydı kaldır'),
            onPressed: _busy
                ? null
                : () async {
                    if (!await confirmDelete(context, 'Spor kaydı') ||
                        !context.mounted) {
                      return;
                    }
                    setState(() => _busy = true);
                    final store = DayliScope.of(context);
                    final success = await performAction(
                      context,
                      () => store.saveSport(done: false, minutes: 0),
                    );
                    if (!context.mounted) return;
                    if (success) {
                      Navigator.pop(context);
                    } else {
                      setState(() => _busy = false);
                    }
                  },
          ),
      ],
    ),
  );
}
