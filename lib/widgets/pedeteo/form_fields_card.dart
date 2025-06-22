// =====================================================
// 7. widgets/pedeteo/form_fields_card.dart
// =====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stampcamera/providers/autos/pedeteo_provider.dart';
import 'package:stampcamera/widgets/common/custom_dropdown_field.dart';

class FormFieldsCard extends ConsumerWidget {
  const FormFieldsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.read(pedeteoOptionsProvider).value!;
    final fieldPermissions = options.fieldPermissions;
    final initialValues = options.initialValues;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Datos del Registro',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Condición
            if (fieldPermissions['condicion'] != null)
              _buildCondicionField(
                ref,
                options,
                initialValues,
                fieldPermissions,
              ),

            const SizedBox(height: 12),

            // Zona de Inspección
            if (fieldPermissions['zona_inspeccion'] != null)
              _buildZonaInspeccionField(
                ref,
                options,
                initialValues,
                fieldPermissions,
              ),

            const SizedBox(height: 12),

            // Bloque
            if (fieldPermissions['bloque'] != null)
              _buildBloqueField(ref, options, initialValues, fieldPermissions),
          ],
        ),
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
