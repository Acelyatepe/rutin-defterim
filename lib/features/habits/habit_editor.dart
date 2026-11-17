import 'package:flutter/material.dart';
import '../../app/dayli_scope.dart';
import '../../core/widgets/form_helpers.dart';
import '../../data/models.dart';

const habitIcons = [
  Icons.spa_outlined,
  Icons.menu_book_outlined,
  Icons.school_outlined,
  Icons.directions_walk_rounded,
  Icons.self_improvement_rounded,
  Icons.favorite_border_rounded,
];
const habitIconLabels = [
  'Yaprak',
  'Kitap',
  'Öğrenme',
  'Yürüyüş',
  'Dinginlik',
  'Kalp',
];
const habitColors = [
  Color(0xFFDDEAD7),
  Color(0xFFE6F0F7),
  Color(0xFFEFEAF7),
  Color(0xFFF8E7DB),
];
const habitColorLabels = ['Yeşil', 'Mavi', 'Lila', 'Şeftali'];

class HabitEditor extends StatefulWidget {
  const HabitEditor({super.key, this.habit});
  final Habit? habit;
  @override
  State<HabitEditor> createState() => _HabitEditorState();
}

class _HabitEditorState extends State<HabitEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.habit?.name);
  late final _target = TextEditingController(
    text: '${widget.habit?.target ?? 1}',
  );
  late int _icon = widget.habit?.icon ?? 0;
  late int _color = widget.habit?.color ?? 0;
  bool _busy = false;
  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: FormBody(
      children: [
        Text(
          widget.habit == null ? 'Yeni bir alışkanlık' : 'Alışkanlığı düzenle',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _name,
          autofocus: widget.habit == null,
          maxLength: 60,
          decoration: const InputDecoration(
            labelText: 'Alışkanlık adı',
            hintText: 'Örneğin, Almanca çalış',
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Bir alışkanlık adı yaz.' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _target,
          maxLength: 3,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Günlük hedef (tekrar)',
            helperText: 'Günde bir kez için 1 yaz.',
          ),
          validator: (v) {
            final n = int.tryParse(v ?? '');
            return n == null || n < 1 || n > 100
                ? '1–100 arasında bir hedef yaz.'
                : null;
          },
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('İkon ve renk'),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < habitIcons.length; i++)
                  IconButton.filledTonal(
                    tooltip: habitIconLabels[i],
                    isSelected: _icon == i,
                    onPressed: () => setState(() => _icon = i),
                    icon: Icon(habitIcons[i]),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < habitColors.length; i++)
                  ChoiceChip(
                    label: Text(habitColorLabels[i]),
                    avatar: CircleAvatar(
                      backgroundColor: habitColors[i],
                      radius: 8,
                    ),
                    selected: _color == i,
                    onSelected: (_) => setState(() => _color = i),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy
              ? null
              : () async {
                  if (!_form.currentState!.validate()) return;
                  setState(() => _busy = true);
                  final store = DayliScope.of(context);
                  final success = await performAction(
                    context,
                    () => store.saveHabit(
                      id: widget.habit?.id,
                      name: _name.text,
                      target: int.parse(_target.text),
                      icon: _icon,
                      color: _color,
                    ),
                  );
                  if (!context.mounted) return;
                  if (success) {
                    Navigator.pop(context);
                  } else {
                    setState(() => _busy = false);
                  }
                },
          child: Text(
            _busy
                ? 'Kaydediliyor…'
                : widget.habit == null
                ? 'Alışkanlığı ekle'
                : 'Değişiklikleri kaydet',
          ),
        ),
      ],
    ),
  );
}
