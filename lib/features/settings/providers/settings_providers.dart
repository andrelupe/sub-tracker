import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_providers.g.dart';

const _themeModeKey = 'theme_mode';
const _analyticsEnabledKey = 'analytics_enabled';
const _analyticsBannerDismissedKey = 'analytics_banner_dismissed';

@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    _loadThemeMode();
    return ThemeMode.system;
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);
    if (value != null) {
      state = _themeModeFromString(value);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  static ThemeMode _themeModeFromString(String value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}

/// Whether the Analytics screen is enabled.
///
/// Disabled by default. Persisted in SharedPreferences.
@Riverpod(keepAlive: true)
class AnalyticsEnabledNotifier extends _$AnalyticsEnabledNotifier {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_analyticsEnabledKey);
    if (value != null) {
      state = value;
    }
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsEnabledKey, state);
  }

  Future<void> setEnabled({required bool enabled}) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsEnabledKey, enabled);
  }
}

/// Whether the analytics promotional banner on the Home screen has been
/// permanently dismissed by the user.
@Riverpod(keepAlive: true)
class AnalyticsBannerDismissedNotifier
    extends _$AnalyticsBannerDismissedNotifier {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_analyticsBannerDismissedKey);
    if (value != null) {
      state = value;
    }
  }

  Future<void> dismiss() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsBannerDismissedKey, true);
  }
}
