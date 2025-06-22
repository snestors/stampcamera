// widgets/common/custom_dropdown_field.dart
import 'package:flutter/material.dart';

class CustomDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<dynamic> items;
  final bool enabled;
  final Function(T?)? onChanged;
  final DropdownMenuItem<T> Function(dynamic) itemBuilder;

  const CustomDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    this.enabled = true,
    this.onChanged,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Si no es editable, mostrar como TextField de solo lectura
    if (!enabled) {
      // Buscar el item de forma segura
      String displayText = 'No seleccionado';

      try {
        for (final item in items) {
          if (item.value == value) {
            displayText = item.label ?? 'Sin etiqueta';
            break;
          }
        }
      } catch (e) {
        debugPrint('Error finding item: $e');
      }

      return TextFormField(
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        initialValue: displayText,
      );
    }

    // Si es editable, mostrar dropdown normal
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        isExpanded: true,
        items: items
            .map<DropdownMenuItem<T>>((item) => itemBuilder(item))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
