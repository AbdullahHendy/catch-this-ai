import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:catch_this_ai/features/tracker/presentation/view_model/tracker_view_model.dart';
import 'package:catch_this_ai/features/tracker/presentation/widgets/daily_count_card.dart';

// Main page for tracking keywords
// TODO: 1. Fix the DailyCountCard to show daily counts instead of last keyword, see daily_count_card.dart
//       2. Add more cards and stuff for better UI/UX
class TrackerPage extends StatelessWidget {
  const TrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<TrackingViewModel>();
    final trackedKeyword = appState.lastKeyword;
    final count = appState.totalCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CATCH THIS AI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        animateColor: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DailyCountCard(trackedKeyword: trackedKeyword),
            const SizedBox(height: 10),
            Text('Total Tracked Keywords: $count'),
          ],
        ),
      ),
    );
  }
}
