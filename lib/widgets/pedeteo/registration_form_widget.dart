// =====================================================
// 6. widgets/pedeteo/registration_form_widget.dart
// =====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stampcamera/providers/autos/pedeteo_provider.dart';
import 'package:stampcamera/widgets/autos/card_detalle_registro_vin.dart';

import 'package:stampcamera/widgets/pedeteo/form_fields_card.dart';
import 'package:stampcamera/widgets/pedeteo/camera_card.dart';
import 'package:stampcamera/widgets/pedeteo/action_buttons.dart';
import 'package:stampcamera/widgets/pedeteo/error_message_widget.dart';

class PedeteoRegistrationForm extends ConsumerWidget {
  const PedeteoRegistrationForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pedeteoStateProvider);
    final selectedVin = state.selectedVin;

    if (selectedVin == null) {
      return const Center(child: Text('No hay VIN seleccionado'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del vehículo
          DetalleRegistroCard(registro: selectedVin),

          const SizedBox(height: 16),

          // Campos del formulario
          const FormFieldsCard(),

          const SizedBox(height: 16),

          // Sección de cámara
          const CameraCard(),

          const SizedBox(height: 24),

          // Botones de acción
          const ActionButtons(),

          // Mensaje de error
          if (state.errorMessage != null)
            ErrorMessageWidget(
              message: state.errorMessage!,
              onDismiss: () =>
                  ref.read(pedeteoStateProvider.notifier).clearError(),
            ),
        ],
      ),
    );
  }
}
