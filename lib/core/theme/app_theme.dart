import 'package:flutter/material.dart';

/// Defines the application's theme using Material 3
class AppTheme {
  static final theme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 228, 49, 168),
    ),
  );
}
