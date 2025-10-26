import 'package:catch_this_ai/features/stats/presentation/view_model/stats_view_model.dart';
import 'package:catch_this_ai/features/stats/widgets/stats_chart_container.dart';
import 'package:flutter/material.dart';
import 'package:catch_this_ai/features/stats/widgets/stats_card.dart';
import 'package:provider/provider.dart';

/// Main page for stats and analytics
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final statsState = context.watch<StatsViewModel>();

    final dayCount = statsState.totalDayCount;
    final weekCount = statsState.totalWeekCount;
    final monthCount = statsState.totalMonthCount;

    final dayChange = statsState.dayChangePercentage;
    final weekChange = statsState.weekChangePercentage;
    final monthChange = statsState.monthChangePercentage;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'STATISTICS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        animateColor: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Section (Summary Cards)
            Text(
              'Overview',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: StatCard(
                    title: 'TODAY',
                    value: '$dayCount',
                    subtitle: dayChange > 0
                        ? '+$dayChange% vs \nyesterday'
                        : '$dayChange% vs \nyesterday',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    title: 'THIS WEEK',
                    value: '$weekCount',
                    subtitle: weekChange > 0
                        ? '+$weekChange% vs \nlast week'
                        : '$weekChange% vs \nlast week',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    title: 'THIS MONTH',
                    value: '$monthCount',
                    subtitle: monthChange > 0
                        ? '+$monthChange% vs \nlast month'
                        : '$monthChange% vs \nlast month',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Trends Section (Line Charts)
            Text(
              'Trends',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Chart container
            StatsChartContainer(),
          ],
        ),
      ),
    );
  }
}
