import 'package:flutter/material.dart';
import '../../app/dayli_scope.dart';
import '../../core/widgets/form_helpers.dart';

class WaterCard extends StatelessWidget {
  const WaterCard({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DayliScope.of(context);
    final r = store.record;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: dark ? const Color(0xFF253C49) : const Color(0xFFE6F0F7),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Su takibi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${r.water} / ${r.waterGoal} ml',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (r.water / r.waterGoal).clamp(0, 1),
                minHeight: 7,
                semanticsLabel: 'Günlük su hedefi',
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final amount in [250, 500])
                  FilledButton.tonal(
                    onPressed: () =>
                        performAction(context, () => store.changeWater(amount)),
                    child: Text('+$amount ml'),
                  ),
                TextButton(
                  onPressed: r.water == 0
                      ? null
                      : () => performAction(
                          context,
                          () => store.changeWater(-250),
                        ),
                  child: const Text('−250 ml'),
                ),
                TextButton(
                  onPressed: () =>
                      showDayliSheet(context, const _WaterEditor()),
                  child: const Text('Miktar gir'),
                ),
              ],
            ),
            Text(
              r.water >= r.waterGoal
                  ? 'Bugünkü hedefine ulaştın.'
                  : 'Bir bardak daha, küçük bir adım.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterEditor extends StatefulWidget {
  const _WaterEditor();
  @override
  State<_WaterEditor> createState() => _WaterEditorState();
}

class _WaterEditorState extends State<_WaterEditor> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  bool _subtract = false;
  bool _busy = false;
  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: FormBody(
      children: [
        Text('Su miktarı', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        TextFormField(
          controller: _amount,
          autofocus: true,
          maxLength: 5,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Miktar (ml)'),
          validator: (v) {
            final n = int.tryParse(v ?? '');
            return n == null || n < 1 || n > 10000
                ? '1–10000 ml arasında bir miktar yaz.'
                : null;
          },
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Bu miktarı azalt'),
          value: _subtract,
          onChanged: (v) => setState(() => _subtract = v),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy
              ? null
              : () async {
                  if (!_form.currentState!.validate()) return;
                  setState(() => _busy = true);
                  final store = DayliScope.of(context);
                  final success = await performAction(
                    context,
                    () => store.changeWater(
                      int.parse(_amount.text) * (_subtract ? -1 : 1),
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
      ],
    ),
  );
}
