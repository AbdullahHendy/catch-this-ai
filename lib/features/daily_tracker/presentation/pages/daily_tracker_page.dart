import 'package:catch_this_ai/features/daily_tracker/presentation/widgets/daily_tracker_history_list_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:catch_this_ai/features/daily_tracker/presentation/view_model/daily_tracker_view_model.dart';
import 'package:catch_this_ai/features/daily_tracker/presentation/widgets/daily_tracker_count_card.dart';

/// Main page for tracking keywords
// TODO: 1. Think about adding more UI elements below the DailyCountCard
class DailyTrackerPage extends StatelessWidget {
  const DailyTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dailyTrackerState = context.watch<DailyTrackerViewModel>();
    final count = dailyTrackerState.totalDayCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CATCH THIS AI',
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(flex: 3, child: DailyTrackerHistoryListView()),
            const SizedBox(height: 10),
            DailyTrackerCountCard(totalDayCount: count),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
