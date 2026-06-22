// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const double _baseIconSize = 24.0;

  /// Build ThemeData với iconSize được scale theo màn hình.
  static ThemeData build({required double scale}) => ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        iconTheme: IconThemeData(size: _baseIconSize * scale),
      );
}
