import 'package:flutter/material.dart';
import '../core/notifications.dart';
import '../data/dayli_store.dart';

class DayliScope extends InheritedNotifier<DayliStore> {
  const DayliScope({
    super.key,
    required DayliStore store,
    required this.notifications,
    required super.child,
  }) : super(notifier: store);
  final DayliNotifications notifications;
  static DayliStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DayliScope>()!.notifier!;
  static DayliNotifications reminders(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DayliScope>()!.notifications;
}
