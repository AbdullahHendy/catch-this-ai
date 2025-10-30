// lib/features/stats/widgets/stats_chart.dart

import 'package:catch_this_ai/features/stats/widgets/stats_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:catch_this_ai/features/stats/presentation/view_model/stats_view_model.dart';

class StatsChartContainer extends StatelessWidget {
  const StatsChartContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final statsState = context.watch<StatsViewModel>();
    final timeFrames = statsState.chartTimeFrames;
    final chartTimeFrameIndex = statsState.chartTimeFrameIndex;

    return Container(
      height: 251,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Filter row for day/week/month toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(timeFrames.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(
                    timeFrames[index],
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  selected: chartTimeFrameIndex == index,
                  onSelected: (bool selected) {
                    if (selected && chartTimeFrameIndex != index) {
                      statsState.setChartTimeFrameIndex(index);
                    }
                  },
                ),
              );
            }),
          ),

          const SizedBox(height: 8),

          // bar chart placeholder
          const Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 24),
              child: StatsChart(),
            ),
          ),
        ],
      ),
    );
  }
}
