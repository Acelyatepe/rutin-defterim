import 'package:flutter/material.dart';
import '../../app/dayli_scope.dart';
import '../../core/widgets/page_layout.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DayliScope.of(context);
    final theme = Theme.of(context);
    final elapsed = store.elapsedWeek.length;
    final week = store.week;
    const labels = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pa'];
    final completedTasks = store.data.tasks
        .where((t) => store.elapsedWeek.contains(t.date) && t.done)
        .length;
    return PageLayout(
      children: [
        const PageHeading(
          title: 'Her adım bir ilerleme.',
          subtitle: 'Gününe ve haftana küçük bir bakış.',
        ),
        Card(
          color: theme.colorScheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 32,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
                const SizedBox(height: 16),
                Text(
                  'Kendin için $completedTasks güzel adım',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bu hafta tamamladığın görevler.\nHer küçük çaba birikir.',
                  style: TextStyle(
                    color: theme.colorScheme.onTertiaryContainer,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SectionHeading('Haftalık görünüm', trailing: 'Pazartesi – Pazar'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Günlük toplam ilerleme',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Builder(
                          builder: (_) {
                            final future = week[i].compareTo(store.today) > 0;
                            final available =
                                week[i].compareTo(store.data.startedOn) >= 0 &&
                                !future;
                            final rate = store.dailyProgress(week[i]);
                            return Semantics(
                              label:
                                  '${labels[i]}: ${available ? 'yüzde ${(rate * 100).round()}' : 'veri yok'}',
                              excludeSemantics: true,
                              child: Column(
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      available
                                          ? '${(rate * 100).round()}'
                                          : '–',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 110,
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: FractionallySizedBox(
                                        widthFactor: .55,
                                        heightFactor: rate == 0 ? .025 : rate,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: week[i] == store.today
                                                ? theme.colorScheme.primary
                                                : theme
                                                      .colorScheme
                                                      .primaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      labels[i],
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SectionHeading('Görevler ve alışkanlıklar'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _Rate(
                  label: 'Bugünkü görevler',
                  rate: store.taskRate(store.today),
                ),
                const SizedBox(height: 20),
                _Rate(label: 'Haftalık görevler', rate: store.weeklyTaskRate),
                const SizedBox(height: 20),
                _Rate(
                  label: 'Bugünkü alışkanlıklar',
                  rate: store.habitRate(store.today),
                ),
                const SizedBox(height: 20),
                _Rate(
                  label: 'Haftalık alışkanlıklar',
                  rate: store.weeklyHabitRate,
                ),
              ],
            ),
          ),
        ),
        const SectionHeading('Su ve hareket'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Rate(
                  label:
                      'Bugünkü su · ${store.record.water} / ${store.record.waterGoal} ml',
                  rate: (store.record.water / store.record.waterGoal).clamp(
                    0,
                    1,
                  ),
                ),
                const SizedBox(height: 20),
                _Rate(
                  label:
                      'Haftalık su hedefi · $elapsed günde ${store.waterSuccessDays} gün',
                  rate: elapsed == 0 ? 0 : store.waterSuccessDays / elapsed,
                ),
                const SizedBox(height: 20),
                Text(
                  'Bu hafta ${store.sportDays} gün spor yaptın.',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < 7; i++)
                      Semantics(
                        label:
                            '${labels[i]}: ${store.data.days[week[i]]?.sport == true ? 'spor yapıldı' : 'spor kaydı yok'}',
                        excludeSemantics: true,
                        child: Column(
                          children: [
                            Text(labels[i]),
                            const SizedBox(height: 6),
                            Icon(
                              store.data.days[week[i]]?.sport == true
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'En uzun alışkanlık serisi: ${store.bestStreak} gün',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('Nasıl hesaplanır?', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        const Text(
          'Günlük ilerleme; su hedefi, spor ve varsa görevler ile alışkanlıkların eşit ağırlıklı ortalamasıdır. Su hedefi üzerindeki miktar ek puan getirmez. Boş görev ve alışkanlık listeleri ortalamaya katılmaz. Spor, süre girilmese de tamamlandıysa sayılır.',
        ),
        const SizedBox(height: 8),
        const Text(
          'Hafta Pazartesi başlar. Gelecek günler ve ilk kullanımdan önceki günler hesaba katılmaz. Alışkanlık hedefleri ve su hedefleri geçmiş günlerde korunur. Seri, bugün henüz tamamlamadıysan dün üzerinden devam eder.',
        ),
      ],
    );
  }
}

class _Rate extends StatelessWidget {
  const _Rate({required this.label, required this.rate});
  final String label;
  final double rate;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$label · %${(rate * 100).round()}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: rate,
          minHeight: 7,
          semanticsLabel: label,
        ),
      ),
    ],
  );
}
