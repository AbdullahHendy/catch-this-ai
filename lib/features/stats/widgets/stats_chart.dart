import 'package:catch_this_ai/features/stats/presentation/view_model/stats_view_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class StatsChart extends StatelessWidget {
  const StatsChart({super.key});

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
    TextStyle style = TextStyle(
      color: Colors.grey[600],
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );

    final padEmptyDays = statsState.padEmptyDaysInCharts;
    final entries = statsState.selectedDaysCountsMap.entries.toList();
    final index = value.toInt();
    final date = entries[index].key;

    String text;

    Widget child;

    if (padEmptyDays) {
      final weekday = date.weekday;
      text = switch (weekday) {
        1 => 'M',
        2 => 'T',
        3 => 'W',
        4 => 'T',
        5 => 'F',
        6 => 'S',
        7 => 'S',
        _ => '',
      };

      const int daysBetweenLabels = 3;
      if (statsState.selectedChartTimeFrame == ChartTimeFrame.month) {
        if (index % daysBetweenLabels != 0) {
          text = '';
        }
      }

      child = Text(text, style: style);
    } else {
      style = statsState.selectedChartTimeFrame == ChartTimeFrame.month
          ? style.copyWith(fontSize: 10)
          : style;

      // Get the month name abbreviation, day and year
      final month = DateFormat.MMM().format(date);
      final day = date.day;
      final year = date.year;
      // Stack month, day and year vertically
      child = RotatedBox(
        quarterTurns: -1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Text(day.toString(), style: style),
            Text(month, style: style),
            Text(year.toString().substring(2), style: style),
          ],
        ),
      );
    }

    return SideTitleWidget(meta: meta, space: 4, child: child);
  }

  Widget getLeftTitles(double value, TitleMeta meta) {
    final style = TextStyle(
      color: Colors.grey[600],
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    return SideTitleWidget(
      meta: meta,
      space: 10,
      child: Text(value.toInt().toString(), style: style),
    );
  }

  FlTitlesData titlesData(StatsViewModel statsState) {
    final double reservedSize = statsState.padEmptyDaysInCharts
        ? 32
        : statsState.selectedChartTimeFrame == ChartTimeFrame.week
        ? 80
        : 60;
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: reservedSize,
          getTitlesWidget: (value, meta) =>
              getBottomTitles(value, meta, statsState), // Pass statsState here
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          // only for 30d view and length of selected data is more than 15 show left titles
          // The second condition if for the case when pad empty days is false causing (possible) less than 30 days to be shown
          // It's then fine to stick with the same style as 7d view
          showTitles:
              statsState.selectedChartTimeFrame == ChartTimeFrame.month &&
              statsState.selectedDaysCountsMap.length > 15,
          reservedSize: 40,
          interval: statsState.chartMaxY > 0 ? statsState.chartMaxY / 3 : 1,
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
    final entries = statsState.selectedDaysCountsMap.entries.toList();

    return entries.asMap().entries.map((indexedEntry) {
      final index = indexedEntry.key;
      final count = indexedEntry.value.value;

      // width scales linearly between 4 and 12 based on length of selectedDaysCountsMap (4 at 30, 12 at 0)
      final rodSizeSlope = (4 - 12) / (30 - 0);
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            width: rodSizeSlope * entries.length + 12,
            gradient: _barsGradient(context),
          ),
        ],
        // Only show tooltip for data with length of less than or equal to 15 days
        // This can happen in two cases:
        // 1. 7d view
        // 2. 30d view when pad empty days is false causing (possible) less than 30 days to be shown
        // It's then fine to show tooltip as in 7d view
        showingTooltipIndicators: statsState.selectedDaysCountsMap.length <= 15
            ? [0]
            : [],
      );
    }).toList();
  }
}
