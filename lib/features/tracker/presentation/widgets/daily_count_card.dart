import 'package:flutter/material.dart';
import 'package:catch_this_ai/features/tracker/domain/tracked_keyword.dart';

/// Card to display the daily count of tracked keywords
// TODO: 1. This card currently shows the last tracked keyword and its timestamp, for testing purposes.
//       2. Update it to mainly show the daily count of tracked keywords instead ()
//       3. Need more cards for other stats like weekly, monthly, blah.
class DailyCountCard extends StatelessWidget {
  const DailyCountCard({super.key, required this.trackedKeyword});
  final TrackedKeyword trackedKeyword;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: MergeSemantics(
            child: Wrap(
              children: [
                Text(
                  trackedKeyword.keyword,
                  style: style.copyWith(fontWeight: FontWeight.w200),
                ),
                Text(
                  trackedKeyword.timestamp.toString(),
                  style: style.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
