// =====================================================
// 7. widgets/pedeteo/form_fields_card.dart
// =====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/autos/pedeteo_provider.dart';
import 'package:stampcamera/widgets/common/custom_dropdown_field.dart';

class FormFieldsCard extends ConsumerWidget {
  const FormFieldsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Patrón .when() robusto - Maneja todos los estados
    return ref.watch(pedeteoOptionsProvider).when(
      data: (options) => _buildFormCard(context, ref, options),
      loading: () => _buildCardShell(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(DesignTokens.spaceM),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, _) => _buildCardShell(
        accentColor: AppColors.error,
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error, color: AppColors.error),
              const SizedBox(height: DesignTokens.spaceS),
              Text('Error al cargar opciones: $error'),
            ],
          ),
        ),
      ),
    );
  }

  /// Mismo estilo de tarjeta que DetalleRegistroCard (card del detalle VIN):
  /// fondo blanco, radio L, sombra sutil y accent strip lateral.
  Widget _buildCardShell({required Widget child, Color? accentColor}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Accent strip lateral
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor ?? AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceM),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 Construye el formulario cuando los datos están disponibles
  Widget _buildFormCard(BuildContext context, WidgetRef ref, options) {
    final fieldPermissions = options.fieldPermissions;
    final initialValues = options.initialValues;

    return _buildCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono, mismo patrón que el card del detalle VIN
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.spaceS),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: DesignTokens.spaceS),
              const Text(
                'Datos del Registro',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceM),

          // Condición
          if (fieldPermissions['condicion'] != null)
            _buildCondicionField(
              ref,
              options,
              initialValues,
              fieldPermissions,
            ),

          const SizedBox(height: DesignTokens.spaceS),

          // Zona de Inspección
          if (fieldPermissions['zona_inspeccion'] != null)
            _buildZonaInspeccionField(
              ref,
              options,
              initialValues,
              fieldPermissions,
            ),

          const SizedBox(height: DesignTokens.spaceS),

          // Bloque
          if (fieldPermissions['bloque'] != null)
            _buildBloqueField(ref, options, initialValues, fieldPermissions),
        ],
      ),
    );
  }

  Widget _buildCondicionField(
    WidgetRef ref,
    dynamic options,
    Map<String, dynamic> initialValues,
    Map<String, dynamic> fieldPermissions,
  ) {
    final state = ref.watch(pedeteoStateProvider);
    final field = fieldPermissions['condicion'];
    final condiciones = options.condiciones;
    final currentValue =
        state.formData['condicion'] ?? initialValues['condicion'];

    return CustomDropdownField<String>(
      label: 'Condición',
      value: currentValue,
      items: condiciones,
      enabled: field?.editable ?? true,
      onChanged: field?.editable ?? true
          ? (value) => ref
                .read(pedeteoStateProvider.notifier)
                .updateFormField('condicion', value)
          : null,
      itemBuilder: (item) => DropdownMenuItem<String>(
        value: item.value,
        child: Text(item.label, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _buildZonaInspeccionField(
    WidgetRef ref,
    dynamic options,
    Map<String, dynamic> initialValues,
    Map<String, dynamic> fieldPermissions,
  ) {
    final state = ref.watch(pedeteoStateProvider);
    final field = fieldPermissions['zona_inspeccion'];
    final zonas = options.zonasInspeccion;
    final currentValue =
        state.formData['zona_inspeccion'] ?? initialValues['zona_inspeccion'];

    return CustomDropdownField<int>(
      label: 'Zona de Inspección',
      value: currentValue,
      items: zonas,
      enabled: field?.editable ?? true,
      onChanged: field?.editable ?? true
          ? (value) => ref
                .read(pedeteoStateProvider.notifier)
                .updateFormField('zona_inspeccion', value)
          : null,
      itemBuilder: (item) => DropdownMenuItem<int>(
        value: item.value,
        child: Text(item.label, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _buildBloqueField(
    WidgetRef ref,
    dynamic options,
    Map<String, dynamic> initialValues,
    Map<String, dynamic> fieldPermissions,
  ) {
    final state = ref.watch(pedeteoStateProvider);
    final field = fieldPermissions['bloque'];
    final bloques = options.bloques;
    final currentValue = state.formData['bloque'] ?? initialValues['bloque'];

    return CustomDropdownField<int>(
      label: 'Bloque',
      value: currentValue,
      items: bloques,
      enabled: field?.editable ?? true,
      onChanged: field?.editable ?? true
          ? (value) => ref
                .read(pedeteoStateProvider.notifier)
                .updateFormField('bloque', value)
          : null,
      itemBuilder: (item) => DropdownMenuItem<int>(
        value: item.value,
        child: Text(item.label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
