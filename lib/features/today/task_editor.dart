import 'package:flutter/material.dart';
import '../../app/dayli_scope.dart';
import '../../core/widgets/form_helpers.dart';
import '../../data/models.dart';

class TaskEditor extends StatefulWidget {
  const TaskEditor({super.key, this.task});
  final DayTask? task;
  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.task?.name);
  late final _category = TextEditingController(text: widget.task?.category);
  late final _note = TextEditingController(text: widget.task?.note);
  late int? _minute = widget.task?.minute;
  bool _busy = false;
  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final store = DayliScope.of(context);
    final success = await performAction(
      context,
      () => store.saveTask(
        id: widget.task?.id,
        name: _name.text,
        category: _category.text,
        minute: _minute,
        note: _note.text,
      ),
    );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: FormBody(
      children: [
        Text(
          widget.task == null ? 'Gününe bir adım ekle' : 'Görevi düzenle',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _name,
          autofocus: widget.task == null,
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Görev adı',
            hintText: 'Örneğin, kısa bir yürüyüş yap',
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Bir görev adı yaz.' : null,
          onFieldSubmitted: (_) => _save(),
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          initiallyExpanded: widget.task != null,
          title: const Text('Ayrıntılar (isteğe bağlı)'),
          children: [
            TextFormField(
              controller: _category,
              maxLength: 30,
              decoration: const InputDecoration(labelText: 'Kategori'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _minute == null
                            ? TimeOfDay.now()
                            : TimeOfDay(
                                hour: _minute! ~/ 60,
                                minute: _minute! % 60,
                              ),
                      );
                      if (time != null && mounted) {
                        setState(() => _minute = time.hour * 60 + time.minute);
                      }
                    },
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(
                      _minute == null ? 'Saat seç' : clockLabel(_minute!),
                    ),
                  ),
                ),
                if (_minute != null)
                  IconButton(
                    tooltip: 'Saati kaldır',
                    onPressed: () => setState(() => _minute = null),
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Not'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(
            _busy
                ? 'Kaydediliyor…'
                : widget.task == null
                ? 'Görevi ekle'
                : 'Değişiklikleri kaydet',
          ),
        ),
      ],
    ),
  );
}
