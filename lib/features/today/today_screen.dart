import 'package:flutter/material.dart';
import '../../app/dayli_scope.dart';
import '../../core/utils/dayli_date.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/widgets/form_helpers.dart';
import '../settings/settings_screen.dart';
import 'task_editor.dart';
import 'water_card.dart';
import 'sport_card.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DayliScope.of(context);
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 6
        ? 'İyi geceler.'
        : hour < 12
        ? 'Günaydın.'
        : hour < 18
        ? 'İyi günler.'
        : 'İyi akşamlar.';
    final tasks = store.tasks;
    final completed = tasks.where((t) => t.done).length;
    final habitCount = store.record.habitTargets.keys
        .where(store.record.habitDone)
        .length;
    final progress = store.dailyProgress(store.today);
    return PageLayout(
      children: [
        PageHeading(
          title: greeting,
          subtitle: DayliDate.full(store.clock()),
          action: IconButton(
            tooltip: 'Ayarlar',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ),
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bugünkü ilerleme',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: progress),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 250),
                  builder: (context, value, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '%${(value * 100).round()}',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontSize: 42,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          semanticsLabel: 'Günlük ilerleme',
                          backgroundColor: theme.colorScheme.surface.withValues(
                            alpha: .55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Küçük adımlar, güzel bir gün.',
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ),
        SectionHeading(
          'Bugünkü görevler',
          trailing: '$completed / ${tasks.length} tamamlandı',
        ),
        if (tasks.isEmpty)
          const EmptyCard(
            icon: Icons.checklist_rounded,
            title: 'Bugün için ilk adımını seç.',
            detail: 'Bir görev ekle, gününe küçük bir yer aç.',
          )
        else
          Card(
            child: Column(
              children: [
                for (final task in tasks) ...[
                  if (task != tasks.first)
                    const Divider(height: 1, indent: 20, endIndent: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: task.done,
                          semanticLabel: '${task.name} tamamlandı',
                          onChanged: (_) => performAction(
                            context,
                            () => store.toggleTask(task.id),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                showDayliSheet(context, TaskEditor(task: task)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 4,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.name,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          decoration: task.done
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: task.done
                                              ? theme
                                                    .colorScheme
                                                    .onSurfaceVariant
                                              : theme.colorScheme.onSurface,
                                        ),
                                  ),
                                  if (task.category.isNotEmpty ||
                                      task.minute != null)
                                    Text(
                                      [
                                        if (task.category.isNotEmpty)
                                          task.category,
                                        if (task.minute != null)
                                          clockLabel(task.minute!),
                                      ].join(' · '),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  if (task.note.isNotEmpty)
                                    Text(
                                      task.note,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: '${task.name} seçenekleri',
                          onSelected: (value) async {
                            if (value == 'edit') {
                              await showDayliSheet(
                                context,
                                TaskEditor(task: task),
                              );
                            } else if (await confirmDelete(
                                  context,
                                  task.name,
                                ) &&
                                context.mounted) {
                              await performAction(
                                context,
                                () => store.deleteTask(task.id),
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Düzenle'),
                            ),
                            PopupMenuItem(value: 'delete', child: Text('Sil')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => showDayliSheet(context, const TaskEditor()),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Hızlı görev ekle'),
        ),
        const SectionHeading('Kendine iyi bak'),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 560 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.3) {
              return const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [WaterCard(), SizedBox(height: 14), SportCard()],
              );
            }
            return const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: WaterCard()),
                SizedBox(width: 14),
                Expanded(child: SportCard()),
              ],
            );
          },
        ),
        const SectionHeading('Alışkanlık özeti'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.habits.isEmpty
                      ? 'Sana iyi gelen bir rutin seç.'
                      : '$habitCount / ${store.habits.length} alışkanlık tamamlandı',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  store.habits.isEmpty
                      ? 'Alışkanlıklar sekmesinden kendi rutinini oluşturabilirsin.'
                      : 'Her tekrar, kendine ayırdığın bir an.',
                ),
                if (store.habits.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: store.habitRate(store.today),
                    semanticsLabel: 'Bugünkü alışkanlıklar',
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
