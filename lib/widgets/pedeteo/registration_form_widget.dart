// =====================================================
// 6. widgets/pedeteo/registration_form_widget.dart
// =====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/autos/pedeteo_provider.dart';
import 'package:stampcamera/widgets/autos/card_detalle_registro_vin.dart';

import 'package:stampcamera/widgets/pedeteo/form_fields_card.dart';
import 'package:stampcamera/widgets/pedeteo/camera_card.dart';
import 'package:stampcamera/widgets/pedeteo/action_buttons.dart';
import 'package:stampcamera/widgets/pedeteo/error_message_widget.dart';

class PedeteoRegistrationForm extends ConsumerStatefulWidget {
  const PedeteoRegistrationForm({super.key});

  @override
  ConsumerState<PedeteoRegistrationForm> createState() => _PedeteoRegistrationFormState();
}

class _PedeteoRegistrationFormState extends ConsumerState<PedeteoRegistrationForm> {
  String? _lastShownUrgentVin;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pedeteoStateProvider);
    final selectedVin = state.selectedVin;

    if (selectedVin == null) {
      return const Center(child: Text('No hay VIN seleccionado'));
    }

    // Mostrar modal de urgente si es nuevo VIN urgente
    if (selectedVin.urgente && _lastShownUrgentVin != selectedVin.vin) {
      _lastShownUrgentVin = selectedVin.vin;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUrgentModal(context);
      });
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

  void _showUrgentModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        backgroundColor: AppColors.error,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: Colors.white,
            ),
            SizedBox(height: DesignTokens.spaceM),
            Text(
              'UNIDAD URGENTE',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeL,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignTokens.spaceS),
            Text(
              'Esta unidad tiene prioridad alta',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'ENTENDIDO',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
