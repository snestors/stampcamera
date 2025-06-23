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
      left: 0,
      right: 0,
      child: CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 8), // 8px de separación del TextField
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
          ), // Margen como el SearchBar
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            shadowColor: Colors.black.withValues(alpha: 0.2),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250, minHeight: 50),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: searchResults.isEmpty
                  ? _buildEmptyState()
                  : _buildResultsList(searchResults),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.search_off, color: Colors.grey, size: 20),
          SizedBox(width: 12),
          Text(
            'No se encontraron resultados',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<RegistroGeneral> results) {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Colors.grey.withValues(alpha: 0.2),
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final registro = results[index];
        return _buildResultItem(registro);
      },
    );
  }

  Widget _buildResultItem(RegistroGeneral registro) {
    return InkWell(
      onTap: () => onSelectVin(registro),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // VIN principal
            Text(
              registro.vin,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            // Información secundaria
            Row(
              children: [
                // Marca y modelo
                Expanded(
                  child: Text(
                    '${registro.marca ?? ''} ${registro.modelo ?? ''}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Serie
                if (registro.serie != null && registro.serie!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Serie: ${registro.serie}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
