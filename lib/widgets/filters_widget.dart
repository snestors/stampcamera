// widgets/autos/inventario_filters_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InventarioFiltersWidget extends ConsumerWidget {
  const InventarioFiltersWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            label: 'Sin Inventario',
            icon: Icons.playlist_add,
            onTap: () => _filterSinInventario(ref),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Con Inventario',
            icon: Icons.playlist_add_check,
            onTap: () => _filterConInventario(ref),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Por Agente',
            icon: Icons.business,
            onTap: () => _showAgenteFilter(context, ref),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Estadísticas',
            icon: Icons.analytics,
            onTap: () => _showStats(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _filterSinInventario(WidgetRef ref) {}

  void _filterConInventario(WidgetRef ref) {}

  void _showAgenteFilter(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Filtrar por Agente',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.business),
                      title: const Text('TLI ADUANAS S.A.C.'),
                      onTap: () {
                        Navigator.pop(context);
                        _applyAgenteFilter(ref, 1);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.business),
                      title: const Text('NEPTUNIA S.A.'),
                      onTap: () {
                        Navigator.pop(context);
                        _applyAgenteFilter(ref, 2);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.business),
                      title: const Text('COSMOS AGENCIA MARITIMA'),
                      onTap: () {
                        Navigator.pop(context);
                        _applyAgenteFilter(ref, 3);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.clear_all),
                      title: const Text('Limpiar filtro'),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyAgenteFilter(WidgetRef ref, int agenteId) {}

  void _showStats(BuildContext context) {
    // Navegar a estadísticas
    // context.push('/autos/inventario/estadisticas');
  }
}
