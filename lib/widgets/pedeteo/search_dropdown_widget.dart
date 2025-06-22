// =====================================================
// 3. widgets/pedeteo/search_dropdown_widget.dart
// =====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stampcamera/providers/autos/pedeteo_provider.dart';
import 'package:stampcamera/models/autos/registro_general_model.dart';

class PedeteoSearchDropdown extends ConsumerWidget {
  final LayerLink layerLink;
  final Function(RegistroGeneral) onSelectVin;
  final VoidCallback onHide;

  const PedeteoSearchDropdown({
    super.key,
    required this.layerLink,
    required this.onSelectVin,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(pedeteoSearchResultsProvider);

    return Positioned(
      width: MediaQuery.of(context).size.width - 32,
      child: CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 60),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: searchResults.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No se encontraron resultados'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final vin = searchResults[index];
                      return ListTile(
                        dense: true,
                        title: Text(vin.vin),
                        subtitle: Text(
                          '${vin.marca ?? ''} ${vin.modelo ?? ''} - Serie: ${vin.serie ?? 'N/A'}',
                        ),
                        onTap: () => onSelectVin(vin),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
