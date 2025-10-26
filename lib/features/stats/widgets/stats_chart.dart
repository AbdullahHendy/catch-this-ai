import 'package:catch_this_ai/features/stats/presentation/view_model/stats_view_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatsChart extends StatelessWidget {
  const StatsChart({super.key});

  static int dayToShow = 1;

  @override
  Widget build(BuildContext context) {
    final statsState = context.watch<StatsViewModel>();

    return BarChart(
      BarChartData(
        barTouchData: barTouchData,
        titlesData: titlesData(statsState),
        borderData: borderData,
        barGroups: barGroups(context, statsState),
        gridData: const FlGridData(show: false),
        alignment: BarChartAlignment.spaceEvenly,
        maxY: statsState.chartMaxY,
      ),
    );
  }

  BarTouchData get barTouchData => BarTouchData(
    enabled: false,

    touchTooltipData: BarTouchTooltipData(
      getTooltipColor: (group) => Colors.transparent,
      tooltipPadding: EdgeInsets.zero,
      tooltipMargin: 4,
      getTooltipItem:
          (
            BarChartGroupData group,
            int groupIndex,
            BarChartRodData rod,
            int rodIndex,
          ) {
            return BarTooltipItem(
              rod.toY.round().toString(),
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            );
          },
    ),
  );

  Widget getBottomTitles(
    double value,
    TitleMeta meta,
    StatsViewModel statsState,
  ) {
    final style = TextStyle(
      color: Colors.grey[600],
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    final weekday = value.toInt();
    String text = switch (weekday) {
      1 => 'M',
      2 => 'T',
      3 => 'W',
      4 => 'T',
      5 => 'F',
      6 => 'S',
      7 => 'S',
      _ => '',
    };

    // If 30d view (implied by data size > 20), show labels with stride of 3 days
    const int daysBetweenLabels = 3;
    if (statsState.selectedDaysCountsMap.length > 20) {
      if (weekday == dayToShow) {
        // Update dayToShow to be 3 days later, wrapping around the week
        dayToShow += daysBetweenLabels;
        if (dayToShow > 7) {
          dayToShow -= 7;
        }
        if (dayToShow == 0) {
          dayToShow = 7;
        }
      } else {
        text = '';
      }
    }

    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Text(text, style: style),
    );
  }

  Widget getLeftTitles(double value, TitleMeta meta) {
    final style = TextStyle(
      color: Colors.grey[600],
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Text(value.toInt().toString(), style: style),
    );
  }

  FlTitlesData titlesData(StatsViewModel statsState) {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) =>
              getBottomTitles(value, meta, statsState), // Pass statsState here
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          // only for 30d view (implied by data size > 20), show left titles
          showTitles: statsState.selectedDaysCountsMap.length > 20,
          reservedSize: 40,
          interval: statsState.chartMaxY / 3,
          getTitlesWidget: getLeftTitles,
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  FlBorderData get borderData => FlBorderData(show: false);

  LinearGradient _barsGradient(BuildContext context) => LinearGradient(
    colors: [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.primaryContainer,
    ],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  List<BarChartGroupData> barGroups(
    BuildContext context,
    StatsViewModel statsState,
  ) {
    return statsState.selectedDaysCountsMap.entries.map((entry) {
      final keyword = entry.key;
      final count = entry.value;
      return BarChartGroupData(
        x: keyword.weekday,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            gradient: _barsGradient(context),
          ),
        ],
        // Only show tooltip for small maps
        showingTooltipIndicators: statsState.selectedDaysCountsMap.length <= 20
            ? [0]
            : [],
      );
    }).toList();
  }
}
