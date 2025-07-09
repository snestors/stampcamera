// lib/widgets/autos/dialogs/contenedor_search_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/contenedor_model.dart';
import 'package:stampcamera/providers/autos/contenedor_provider.dart';
import 'package:stampcamera/core/core.dart';

class ContenedorSearchDialog extends ConsumerStatefulWidget {
  final Function(int contenedorId, String contenedorText) onContenedorSelected;

  const ContenedorSearchDialog({super.key, required this.onContenedorSelected});

  @override
  ConsumerState<ContenedorSearchDialog> createState() =>
      _ContenedorSearchDialogState();
}

class _ContenedorSearchDialogState
    extends ConsumerState<ContenedorSearchDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contenedoresAsync = ref.watch(contenedorProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.search, color: AppColors.accent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Buscar Contenedor',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Campo de búsqueda
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por número de contenedor...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),

            const SizedBox(height: 16),

            // Lista de contenedores
            Expanded(
              child: contenedoresAsync.when(
                data: (contenedores) => _buildContenedoresList(contenedores),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _buildErrorWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenedoresList(List<ContenedorModel> contenedores) {
    // Filtrar contenedores por búsqueda
    final contenedoresFiltrados = _searchQuery.isEmpty
        ? contenedores
        : contenedores.where((contenedor) {
            return contenedor.nContenedor.toLowerCase().contains(
                  _searchQuery,
                ) ||
                contenedor.naveDescarga.naveDescarga.toLowerCase().contains(
                  _searchQuery,
                );
          }).toList();

    if (contenedoresFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.inventory_2 : Icons.search_off,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No hay contenedores disponibles'
                  : 'No se encontraron contenedores para "$_searchQuery"',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: contenedoresFiltrados.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final contenedor = contenedoresFiltrados[index];
        return _buildContenedorItem(contenedor);
      },
    );
  }

  Widget _buildContenedorItem(ContenedorModel contenedor) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.accent,
        child: Icon(Icons.inventory_2, color: Colors.white, size: 20),
      ),
      title: Text(
        contenedor.nContenedor,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nave: ${contenedor.naveDescarga.displayName}',
            style: const TextStyle(fontSize: 12),
          ),
          if (contenedor.zonaInspeccion != null)
            Text(
              'Zona: ${contenedor.zonaInspeccion!.value}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // Crear el texto descriptivo similar al JSON
        final contenedorText =
            '${contenedor.nContenedor} - ${contenedor.naveDescarga.displayName}';

        widget.onContenedorSelected(contenedor.id, contenedorText);
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar contenedores',
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(contenedorProvider),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
