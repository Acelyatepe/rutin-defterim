import 'package:flutter/material.dart';

class PageLayout extends StatelessWidget {
  const PageLayout({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Rutin Defterim',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -.5,
              ),
            ),
          ),
          ?action,
        ],
      ),
      const SizedBox(height: 24),
      Text(title, style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 6),
      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 24),
    ],
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.trailing});
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 14),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (trailing != null)
          Text(trailing!, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}
