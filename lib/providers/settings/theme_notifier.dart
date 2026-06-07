import 'package:done_today/providers/auth/auth_notifier.dart';
import 'package:done_today/state/auth/auth_state.dart';
import 'package:done_today/storage/hive/hive_service.dart';
import 'package:done_today/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeState {
  final ThemeMode themeMode;
  final Color seedColor;
  final bool useBlackMode;
  final bool use24HourFormat;
  final bool useFloatingNavBar;
  ThemeState({
    required this.themeMode,
    required this.seedColor,
    this.useBlackMode = false,
    this.use24HourFormat = false,
    this.useFloatingNavBar = true,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    Color? seedColor,
    bool? useBlackMode,
    bool? use24HourFormat,
    bool? useFloatingNavBar,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
      useBlackMode: useBlackMode ?? this.useBlackMode,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      useFloatingNavBar: useFloatingNavBar ?? this.useFloatingNavBar,
    );
  }
}

final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeState>(() {
  return ThemeNotifier();
});

class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    // Reset theme settings on logout to match cleared storage
    ref.listen(authNotifierProvider, (previous, next) {
      if (next is AuthLoggedOut) {
        state = _loadThemeSettings();
      }
    });

    Future.microtask(() => initializeThemeSettings());
    return _loadThemeSettings();
  }

  ThemeData get lightTheme => AppTheme.lightTheme(seedColor: state.seedColor);
  ThemeData get darkTheme => AppTheme.darkTheme(
    seedColor: state.seedColor,
    useBlackMode: state.useBlackMode,
  );
  ThemeMode get themeMode => state.themeMode;
  Color get seedColor => state.seedColor;

  /// Load saved settings
  ThemeState _loadThemeSettings() {
    ThemeMode initialMode = ThemeMode.system;
    Color initialColor = Colors.blue;
    return ThemeState(
      themeMode: initialMode,
      seedColor: initialColor,
      useBlackMode: false,
      use24HourFormat: false,
      useFloatingNavBar:
          true, // Default: ON for mobile (user preference), always ON on tablet/desktop
    );
  }

  /// Initialize async - called in build()
  Future<void> initializeThemeSettings() async {
    try {
      ThemeMode initialMode = ThemeMode.system;
      final themeModeIndex = HiveService.getThemeModeIndex();
      if (themeModeIndex != null && themeModeIndex < ThemeMode.values.length) {
        initialMode = ThemeMode.values[themeModeIndex];
      }

      Color initialColor = Colors.blue;
      final seedColorValue = HiveService.getSeedColor();
      if (seedColorValue != null) {
        initialColor = Color(seedColorValue);
      }

      bool useBlackMode = HiveService.getUseBlackMode() ?? false;

      final bool use24HourFormat =
          HiveService.get<bool>('settings', 'use24HourFormat') ?? false;
      final bool useFloatingNavBar =
          HiveService.get<bool>('settings', 'useFloatingNavBar') ?? true;

      state = ThemeState(
        themeMode: initialMode,
        seedColor: initialColor,
        useBlackMode: useBlackMode,
        use24HourFormat: use24HourFormat,
        useFloatingNavBar: useFloatingNavBar,
      );
    } catch (e) {
      // On error, keep default state
    }
  }

  /// Change theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (state.themeMode == mode) return;
    state = state.copyWith(themeMode: mode);
    await HiveService.setThemeModeIndex(mode.index);
  }

  /// Toggle Black Mode
  Future<void> setUseBlackMode(bool value) async {
    if (state.useBlackMode == value) return;
    state = state.copyWith(useBlackMode: value);
    await HiveService.setUseBlackMode(value);
  }

  /// Toggle 24-Hour Time format
  Future<void> setUse24HourFormat(bool value) async {
    if (state.use24HourFormat == value) return;
    state = state.copyWith(use24HourFormat: value);
    await HiveService.put<bool>('settings', 'use24HourFormat', value);
  }

  /// Toggle Floating Navigation Bar
  Future<void> setUseFloatingNavBar(bool value) async {
    if (state.useFloatingNavBar == value) return;
    state = state.copyWith(useFloatingNavBar: value);
    await HiveService.put<bool>('settings', 'useFloatingNavBar', value);
  }

  /// Toggle light/dark only (shortcut)
  Future<void> toggleTheme(bool isDarkMode) async {
    await setThemeMode(isDarkMode ? ThemeMode.dark : ThemeMode.light);
  }

  /// Change seed color
  Future<void> changeSeedColor(Color color) async {
    if (state.seedColor == color) return;
    state = state.copyWith(seedColor: color);
    await HiveService.setSeedColor(color.value);
  }
}
