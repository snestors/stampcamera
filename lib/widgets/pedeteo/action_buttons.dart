// =====================================================
// 12. widgets/pedeteo/action_buttons.dart
// =====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stampcamera/providers/autos/pedeteo_provider.dart';

class ActionButtons extends ConsumerWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pedeteoStateProvider);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _resetForm(ref),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: state.capturedImagePath != null && !state.isLoading
                ? () => _saveAndContinue(context, ref)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A2D3E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Guardar y Continuar'),
          ),
        ),
      ],
    );
  }

  void _resetForm(WidgetRef ref) {
    ref.read(pedeteoStateProvider.notifier).resetForm();
  }

  Future<void> _saveAndContinue(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    await ref.read(pedeteoStateProvider.notifier).saveRegistroOfflineFirst();

    final state = ref.read(pedeteoStateProvider);

    if (state.errorMessage != null && context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color.fromARGB(
            255,
            150,
            5,
            5,
          ), // Verde corporativo
          content: Text(state.errorMessage!),
        ),
      );
    } else if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Registro guardado exitosamente',
            style: TextStyle(
              fontSize: 12, // Más pequeño
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFF059669), // Verde corporativo
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ), // Más compacto
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
