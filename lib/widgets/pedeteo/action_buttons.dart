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

    await ref.read(pedeteoStateProvider.notifier).saveRegistro();

    final state = ref.read(pedeteoStateProvider);

    if (state.errorMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(state.errorMessage!)));
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Registro guardado exitosamente')),
      );
    }
  }
}
