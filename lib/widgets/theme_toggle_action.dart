// Widget para inyectar en AppBar actions
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/providers/theme_provider.dart';

// ============================================================================
// 🎨 WIDGET PARA APPBAR ACTION
// ============================================================================

class ThemeToggleAction extends ConsumerWidget {
  const ThemeToggleAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isDark ? Icons.wb_sunny : Icons.nightlight_round,
            color: primaryColor,
            size: 20,
          ),
        ),
        onPressed: () => themeNotifier.toggleTheme(),
        tooltip: 'Cambiar tema',
      ),
    );
  }
}
