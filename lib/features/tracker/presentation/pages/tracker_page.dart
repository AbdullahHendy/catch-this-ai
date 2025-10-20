import 'package:catch_this_ai/features/tracker/presentation/widgets/day_history_list_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:catch_this_ai/features/tracker/presentation/view_model/tracker_view_model.dart';
import 'package:catch_this_ai/features/tracker/presentation/widgets/daily_count_card.dart';

/// Main page for tracking keywords
// TODO: 1. Think about adding more UI elements below the DailyCountCard
class TrackerPage extends StatelessWidget {
  const TrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<TrackingViewModel>();
    // final dayKeywords = appState.dayKeywordHistory;
    final count = appState.totalDayCount;

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
            const Expanded(flex: 3, child: DayHistoryListView()),
            const SizedBox(height: 10),
            DailyCountCard(totalDayCount: count),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
