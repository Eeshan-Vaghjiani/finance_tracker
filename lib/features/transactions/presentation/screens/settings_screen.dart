import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 16),
          _buildThemeRadio(
            context,
            ref,
            title: 'System Default',
            value: ThemeMode.system,
            groupValue: themeMode,
          ),
          _buildThemeRadio(
            context,
            ref,
            title: 'Light Mode',
            value: ThemeMode.light,
            groupValue: themeMode,
          ),
          _buildThemeRadio(
            context,
            ref,
            title: 'Dark Mode',
            value: ThemeMode.dark,
            groupValue: themeMode,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeRadio(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required ThemeMode value,
    required ThemeMode groupValue,
  }) {
    return RadioListTile<ThemeMode>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: (ThemeMode? newValue) {
        if (newValue != null) {
          ThemeNotifier.setTheme(ref, newValue);
        }
      },
      contentPadding: EdgeInsets.zero,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }
}
