import 'package:flutter/material.dart';

/// Widget to highlight specified keywords for a given text.
class DailyTrackerTextHighlighter extends StatelessWidget {
  const DailyTrackerTextHighlighter({
    super.key,
    required this.text,
    required this.keywords,
  });

  // Full text to display
  final String text;

  // Keywords to highlight within the text
  final List<String> keywords;

  @override
  Widget build(BuildContext context) {
    // 1. Define the base styles
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyMedium!;
    final highlightStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final textAlign = TextAlign.center;

    // If keywords list is empty, return simple Text widget
    if (keywords.isEmpty) {
      return Text(text, style: baseStyle, textAlign: textAlign);
    }

    // Sort keywords by length in descending order to match longer keywords first
    // E.g. if keywords are ["CHAT", "CHAT GPT"], "CHAT GPT" should be matched first
    final uniqueKeywords = keywords.toSet().toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    // join('|') to create a regex pattern that matches any of the keywords
    final pattern = RegExp(
      r'\b(' + uniqueKeywords.map(RegExp.escape).join('|') + r')\b',
      caseSensitive: false,
    );

    final List<TextSpan> spans = [];
    // This splitMapJoin will iterate over all matches and non-matches to build TextSpans
    text.splitMapJoin(
      pattern,
      onMatch: (match) {
        spans.add(TextSpan(text: match.group(0), style: highlightStyle));
        return '';
      },
      onNonMatch: (nonMatch) {
        spans.add(TextSpan(text: nonMatch, style: baseStyle));
        return '';
      },
    );

    return RichText(
      textAlign: textAlign,
      text: TextSpan(children: spans),
    );
  }
}
