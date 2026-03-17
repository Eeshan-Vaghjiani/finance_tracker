import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider to hold the SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final themeString = prefs.getString('theme_mode') ?? 'system';
    
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    String themeString = 'system';
    if (mode == ThemeMode.light) themeString = 'light';
    else if (mode == ThemeMode.dark) themeString = 'dark';
    
    await prefs.setString('theme_mode', themeString);
    state = mode;
  }
}

// A NotifierProvider to manage the current ThemeMode
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

class ThemeNotifier {
  static Future<void> setTheme(WidgetRef ref, ThemeMode mode) async {
    await ref.read(themeModeProvider.notifier).setTheme(mode);
  }
}
