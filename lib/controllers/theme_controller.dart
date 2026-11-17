import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the active [ThemeMode] and persists it across launches.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system);

  static const _key = 'theme_mode';
  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs?.getString(_key);
    value = ThemeMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  void toggle() {
    value = value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _prefs?.setString(_key, value.name);
  }
}

final themeController = ThemeController();
