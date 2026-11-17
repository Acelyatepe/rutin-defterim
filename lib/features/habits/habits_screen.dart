import 'package:flutter/material.dart';
import '../../app/dayli_scope.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/widgets/form_helpers.dart';
import '../../data/models.dart';
import 'habit_editor.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DayliScope.of(context);
    final theme = Theme.of(context);
    return PageLayout(
      children: [
        const PageHeading(
          title: 'Küçük adımlar, her gün.',
          subtitle: 'Kendine ayırdığın zaman, en güzel alışkanlığın.',
        ),
        Card(
          color: theme.colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.spa_outlined,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 32,
                ),
                const SizedBox(height: 16),
                Text(
                  'Mükemmel olmak değil,\ndevam etmek.',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sana iyi gelen rutinlere yer aç.',
                  style: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
        SectionHeading(
          'Alışkanlıkların',
          trailing: '${store.habits.length} günlük rutin',
        ),
        if (store.habits.isEmpty)
          const EmptyCard(
            icon: Icons.spa_outlined,
            title: 'Küçük bir alışkanlıkla başla.',
            detail:
                'Kitap okumak, dil çalışmak veya kendine zaman ayırmak… Seçim senin.',
          ),
        for (final habit in store.habits) ...[
          _HabitCard(habit: habit),
          const SizedBox(height: 14),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => showDayliSheet(context, const HabitEditor()),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Alışkanlık ekle'),
        ),
      ],
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.habit});
  final Habit habit;
  @override
  Widget build(BuildContext context) {
    final store = DayliScope.of(context);
    final theme = Theme.of(context);
    final done = store.record.habitDone(habit.id);
    final count = store.record.habitCounts[habit.id] ?? 0;
    final target = store.record.habitTargets[habit.id] ?? habit.target;
    const labels = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pa'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: habitColors[habit.color],
                  foregroundColor: const Color(0xFF354F45),
                  child: Icon(habitIcons[habit.icon]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit.name, style: theme.textTheme.titleMedium),
                      Text(
                        '$count / $target tekrar · ${store.currentStreak(habit.id)} günlük seri',
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: '${habit.name} seçenekleri',
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                    PopupMenuItem(value: 'delete', child: Text('Sil')),
                  ],
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await showDayliSheet(context, HabitEditor(habit: habit));
                    } else if (await confirmDelete(
                          context,
                          habit.name,
                          detail: 'Önceki günlerin ilerleme kayıtları korunur.',
                        ) &&
                        context.mounted) {
                      await performAction(
                        context,
                        () => store.deleteHabit(habit.id),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () =>
                      performAction(context, () => store.toggleHabit(habit.id)),
                  icon: Icon(
                    done ? Icons.check_circle_rounded : Icons.circle_outlined,
                  ),
                  label: Text(done ? 'Tamamlandı · Geri al' : 'Bugün tamamla'),
                ),
                if (target > 1) ...[
                  IconButton(
                    tooltip: 'Bir tekrar azalt',
                    onPressed: count == 0
                        ? null
                        : () => performAction(
                            context,
                            () => store.incrementHabit(habit.id, -1),
                          ),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  IconButton(
                    tooltip: 'Bir tekrar ekle',
                    onPressed: done
                        ? null
                        : () => performAction(
                            context,
                            () => store.incrementHabit(habit.id, 1),
                          ),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 12,
              children: [
                for (var i = 0; i < 7; i++)
                  Builder(
                    builder: (_) {
                      final date = store.week[i];
                      final completed =
                          store.data.days[date]?.habitDone(habit.id) ?? false;
                      final future = date.compareTo(store.today) > 0;
                      final scheduled = habit.activeOn(date);
                      return Semantics(
                        label:
                            '${labels[i]}: ${completed
                                ? 'tamamlandı'
                                : future
                                ? 'henüz gelmedi'
                                : !scheduled
                                ? 'planlanmadı'
                                : 'tamamlanmadı'}',
                        excludeSemantics: true,
                        child: Column(
                          children: [
                            Text(labels[i], style: theme.textTheme.bodySmall),
                            const SizedBox(height: 8),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: completed
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                completed
                                    ? Icons.check_rounded
                                    : Icons.remove_rounded,
                                size: 17,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
