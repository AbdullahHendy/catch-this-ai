import 'package:catch_this_ai/features/settings/presentation/view_model/settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:catch_this_ai/features/daily_tracker/presentation/view_model/daily_tracker_view_model.dart';
import 'package:catch_this_ai/features/daily_tracker/widgets/daily_tracker_text_highlighter.dart';

/// Widget to display the list of tracked texts for the day
class DailyTrackerHistoryListView extends StatefulWidget {
  const DailyTrackerHistoryListView({super.key});

  @override
  State<DailyTrackerHistoryListView> createState() =>
      _DailyTrackerHistoryListViewState();
}

class _DailyTrackerHistoryListViewState
    extends State<DailyTrackerHistoryListView> {
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

    // Access the DailyTrackerViewModel
    final trackerViewModel = context.watch<DailyTrackerViewModel>();
    trackerViewModel.historyListKey = _key;

    // Access the SettingsViewModel
    final settingsViewModel = context.watch<SettingsViewModel>();
    final keywordsOnly = settingsViewModel.keywordsOnlyMode;

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
        initialItemCount: trackerViewModel.dayTextHistory.length,
        itemBuilder: (context, index, animation) {
          final textItem = trackerViewModel.dayTextHistory[index];
          String formattedDate = dateFormatter.format(textItem.timestamp);
          String formattedTime = timeFormatter.format(textItem.timestamp);

          return SizeTransition(
            sizeFactor: animation,
            child: Padding(
              // Side padding for each list item to avoid touching screen edges
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (keywordsOnly)
                      // Keywords-only view
                      Text(
                        textItem.keywords.join('  -  '),
                        style: textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      )
                    else
                      DailyTrackerTextHighlighter(
                        text: textItem.text,
                        keywords: textItem.keywords,
                      ),
                    const SizedBox(height: 0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                    // Add a faded separator line below each item except the first one
                    if (index != 0)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              colorScheme.outlineVariant.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
