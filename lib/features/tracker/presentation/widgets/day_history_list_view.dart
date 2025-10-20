import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:catch_this_ai/features/tracker/presentation/view_model/tracker_view_model.dart';

/// Widget to display the list of tracked keywords for the day
class DayHistoryListView extends StatefulWidget {
  const DayHistoryListView({super.key});

  @override
  State<DayHistoryListView> createState() => _DayHistoryListViewState();
}

class _DayHistoryListViewState extends State<DayHistoryListView> {
  // GlobalKey for AnimatedList to manage list state
  // This is used to access the AnimatedListState for inserting/removing items
  final _key = GlobalKey();

  // Gradient for fading effect at top of the list
  static const Gradient _maskingGradient = LinearGradient(
    colors: [Colors.transparent, Colors.black],
    stops: [0.0, 0.5],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Access the TrackingViewModel
    final trackerViewModel = context.watch<TrackingViewModel>();
    trackerViewModel.historyListKey = _key;

    // Formatters for only date and only time
    final dateFormatter = DateFormat.yMMMd();
    final timeFormatter = DateFormat.jm();

    return ShaderMask(
      shaderCallback: (bounds) => _maskingGradient.createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: AnimatedList(
        key: _key,
        reverse: true,
        padding: const EdgeInsets.only(top: 100),
        initialItemCount: trackerViewModel.totalDayCount,
        itemBuilder: (context, index, animation) {
          final keyword = trackerViewModel.dayKeywordHistory[index];
          String formattedDate = dateFormatter.format(keyword.timestamp);
          String formattedTime = timeFormatter.format(keyword.timestamp);

          return SizeTransition(
            sizeFactor: animation,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    keyword.keyword,
                    style: theme.textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('|', style: textTheme.bodyLarge),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: textTheme.bodyMedium!.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('|', style: textTheme.bodyLarge),
                  const SizedBox(width: 8),
                  Text(
                    formattedTime,
                    style: textTheme.bodyMedium!.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
