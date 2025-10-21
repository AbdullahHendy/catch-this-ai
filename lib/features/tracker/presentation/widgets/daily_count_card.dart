import 'package:flutter/material.dart';

/// Card to display the daily count of tracked keywords
class DailyCountCard extends StatelessWidget {
  const DailyCountCard({super.key, required this.totalDayCount});
  final int totalDayCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      color: colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'YOU SURVIVED',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge!.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2,
                ),
              ),
              Text(
                totalDayCount.toString(),
                style: textTheme.displayLarge!.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 96,
                  letterSpacing: 5,
                ),
              ),
              Text(
                'TODAY',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge!.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
