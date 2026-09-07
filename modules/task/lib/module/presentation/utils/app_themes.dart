import 'package:flutter/material.dart';

class AppThemes {
  const AppThemes._();

  static final ThemeData light = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
  );

  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
  );

  static ThemeData of(bool isDark) => isDark ? dark : light;
}
