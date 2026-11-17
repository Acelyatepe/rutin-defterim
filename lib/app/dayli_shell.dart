import 'package:flutter/material.dart';
import '../features/habits/habits_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/today/today_screen.dart';
import 'dayli_scope.dart';

class DayliShell extends StatefulWidget {
  const DayliShell({super.key, this.error, this.onRetry});
  final String? error;
  final VoidCallback? onRetry;
  @override
  State<DayliShell> createState() => _DayliShellState();
}

class _DayliShellState extends State<DayliShell> {
  int _index = 0;
  ValueNotifier<int?>? _requestedTab;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = DayliScope.reminders(context).requestedTab;
    if (_requestedTab != notifier) {
      _requestedTab?.removeListener(_openTab);
      _requestedTab = notifier;
      notifier.addListener(_openTab);
      if (notifier.value != null) _index = notifier.value!;
    }
  }

  void _openTab() {
    if (mounted && _requestedTab?.value != null) {
      setState(() => _index = _requestedTab!.value!);
    }
  }

  @override
  void dispose() {
    _requestedTab?.removeListener(_openTab);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.error ?? DayliScope.of(context).message;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (message != null)
              MaterialBanner(
                content: Text(message),
                actions: [
                  if (widget.error != null)
                    TextButton(
                      onPressed: widget.onRetry,
                      child: const Text('Tekrar dene'),
                    )
                  else
                    TextButton(
                      onPressed: () {
                        DayliScope.of(context).message = null;
                        setState(() {});
                      },
                      child: const Text('Tamam'),
                    ),
                ],
              ),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: const [
                  TodayScreen(),
                  HabitsScreen(),
                  ProgressScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny_rounded),
            label: 'Bugün',
          ),
          NavigationDestination(
            icon: Icon(Icons.spa_outlined),
            selectedIcon: Icon(Icons.spa_rounded),
            label: 'Alışkanlıklar',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'İlerleme',
          ),
        ],
      ),
    );
  }
}
