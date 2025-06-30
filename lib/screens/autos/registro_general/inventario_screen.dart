// ============================================================================
// 📂 lib/screens/autos/inventario_base/inventario_screen.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stampcamera/models/autos/inventario_model.dart';

import 'package:go_router/go_router.dart';
import 'package:stampcamera/providers/autos/inventario_provider.dart';

import 'package:stampcamera/widgets/connection_error_screen.dart';

class InventarioScreen extends ConsumerStatefulWidget {
  const InventarioScreen({super.key});

  @override
  ConsumerState<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends ConsumerState<InventarioScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final notifier = ref.read(inventarioBaseProvider.notifier);

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!notifier.isLoadingMore &&
            notifier.hasNextPage &&
            !notifier.isSearching) {
          notifier.loadMore();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventariosAsync = ref.watch(inventarioBaseProvider);
    final notifier = ref.read(inventarioBaseProvider.notifier);

    return Scaffold(
      body: Column(
        children: [
          // ✅ Barra de búsqueda simple
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Buscar por embarque, marca o modelo...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          notifier.clearSearch();
                          _searchFocusNode.unfocus();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {}); // Para actualizar el suffixIcon
                if (value.trim().isEmpty) {
                  notifier.clearSearch();
                } else {
                  notifier.debouncedSearch(value);
                }
              },
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  notifier.search(value);
                  _searchFocusNode.unfocus();
                }
              },
            ),
          ),

          // ✅ Filtros rápidos
          _buildQuickFilters(),

          // ✅ Lista de resultados
          Expanded(child: _buildResultsList(inventariosAsync, notifier)),
        ],
      ),

      // ✅ FAB para crear nuevo inventario
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreate(),
        tooltip: 'Crear Inventario',
        child: const Icon(Icons.add),
      ),
    );
  }

  // ============================================================================
  // MÉTODOS PRIVADOS PARA EL UI
  // ============================================================================

  Widget _buildQuickFilters() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            label: 'Con Imágenes',
            icon: Icons.image,
            onTap: () => _filterByImages(),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Por Marca',
            icon: Icons.filter_list,
            onTap: () => _showMarcaFilter(),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Estadísticas',
            icon: Icons.analytics,
            onTap: () => _showStats(),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Exportar',
            icon: Icons.download,
            onTap: () => _showExportOptions(),
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

  Widget _buildResultsList(
    AsyncValue<List<InventarioBase>> inventariosAsync,
    InventarioBaseNotifier notifier,
  ) {
    return inventariosAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cargando inventarios...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),

      // ✅ Usar ConnectionErrorScreen para manejo inteligente de errores
      error: (error, stackTrace) => ConnectionErrorScreen(
        error: error,
        onRetry: () => notifier.refresh(),
      ),

      data: (inventarios) => _buildDataState(inventarios, notifier),
    );
  }

  Widget _buildDataState(
    List<InventarioBase> inventarios,
    InventarioBaseNotifier notifier,
  ) {
    if (inventarios.isEmpty) {
      return _buildEmptyState(notifier);
    }

    final showLoadMoreIndicator = notifier.hasNextPage && !notifier.isSearching;

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: inventarios.length + (showLoadMoreIndicator ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < inventarios.length) {
            final inventario = inventarios[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _buildInventarioCard(inventario),
            );
          }

          return Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: Column(
              children: [
                if (notifier.isLoadingMore) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text(
                    'Cargando más resultados...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ] else ...[
                  TextButton.icon(
                    onPressed: () => notifier.loadMore(),
                    icon: const Icon(Icons.expand_more),
                    label: const Text('Cargar más'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInventarioCard(InventarioBase inventario) {
    return Card(
      child: InkWell(
        onTap: () => _navigateToDetail(inventario.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Header con información básica
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${inventario.informacionUnidad.marca.marca} ${inventario.informacionUnidad.modelo}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          inventario.informacionUnidad.embarque,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✅ Badge con total de elementos
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${inventario.totalElementos} items',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ✅ Información de la versión
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Versión: ${inventario.informacionUnidad.version}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  Text(
                    'VINs: ${inventario.informacionUnidad.cantidadVins}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ✅ Indicadores de estado
              Row(
                children: [
                  if (inventario.hasImages) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image,
                            size: 12,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${inventario.imageCount}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // ✅ Fecha de actualización
                  Expanded(
                    child: Text(
                      'Actualizado: ${inventario.updateAt}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 10),
                    ),
                  ),

                  // ✅ Menú de acciones
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (action) =>
                        _handleCardAction(action, inventario),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'images',
                        child: Row(
                          children: [
                            Icon(Icons.photo_library, size: 16),
                            SizedBox(width: 8),
                            Text('Ver Imágenes'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(InventarioBaseNotifier notifier) {
    final isSearching = _searchController.text.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.inventory_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'Sin resultados' : 'No hay inventarios',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'No se encontraron inventarios que coincidan con "${_searchController.text}"'
                : 'Aún no hay inventarios registrados',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          if (isSearching) ...[
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                notifier.clearSearch();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar búsqueda'),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => notifier.refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _navigateToCreate(),
                  icon: const Icon(Icons.add),
                  label: const Text('Crear Inventario'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // MÉTODOS DE ACCIÓN
  // ============================================================================

  void _navigateToDetail(int inventarioId) {
    context.push('/autos/inventario/detalle/$inventarioId');
  }

  void _navigateToCreate() {
    context.push('/autos/inventario/crear');
  }

  void _handleCardAction(String action, InventarioBase inventario) {
    switch (action) {
      case 'edit':
        context.push('/autos/inventario/editar/${inventario.id}');
        break;
      case 'images':
        context.push(
          '/autos/inventario/imagenes/${inventario.informacionUnidad.id}',
        );
        break;
      case 'delete':
        _showDeleteDialog(inventario);
        break;
    }
  }

  void _showDeleteDialog(InventarioBase inventario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el inventario de '
          '${inventario.informacionUnidad.marca.marca} ${inventario.informacionUnidad.modelo}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteInventario(inventario.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteInventario(int inventarioId) async {
    try {
      final notifier = ref.read(inventarioBaseProvider.notifier);
      final success = await notifier.deleteInventario(inventarioId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inventario eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar inventario: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================================
  // MÉTODOS DE FILTROS
  // ============================================================================

  void _filterByImages() {
    final notifier = ref.read(inventarioBaseProvider.notifier);

    // Implementar filtro por inventarios con imágenes
    // Por ahora, mostramos un diálogo de info
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtro por Imágenes'),
        content: const Text('Esta funcionalidad se implementará próximamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMarcaFilter() {
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
                'Filtrar por Marca',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Aquí irían las marcas disponibles
                    ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: const Text('Toyota'),
                      onTap: () {
                        Navigator.pop(context);
                        _applyMarcaFilter(1); // ID de ejemplo
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: const Text('Honda'),
                      onTap: () {
                        Navigator.pop(context);
                        _applyMarcaFilter(2); // ID de ejemplo
                      },
                    ),
                    // Más marcas...
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyMarcaFilter(int marcaId) {
    final notifier = ref.read(inventarioBaseProvider.notifier);
    notifier.searchByFilters(marcaId: marcaId);
  }

  void _showStats() {
    context.push('/autos/inventario/estadisticas');
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              'Exportar Inventarios',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_view, color: Colors.green),
              title: const Text('Exportar a Excel'),
              subtitle: const Text('Descarga archivo .xlsx'),
              onTap: () {
                Navigator.pop(context);
                _exportToExcel();
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet, color: Colors.blue),
              title: const Text('Exportar a CSV'),
              subtitle: const Text('Descarga archivo .csv'),
              onTap: () {
                Navigator.pop(context);
                _exportToCsv();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToExcel() async {
    try {
      final service = ref.read(inventarioBaseServiceProvider);
      final downloadUrl = await service.exportToFile(format: 'excel');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Archivo Excel generado exitosamente'),
            action: SnackBarAction(
              label: 'Descargar',
              onPressed: () {
                // Aquí abrir URL o manejar descarga
                // launch(downloadUrl);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar Excel: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToCsv() async {
    try {
      final service = ref.read(inventarioBaseServiceProvider);
      final downloadUrl = await service.exportToFile(format: 'csv');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Archivo CSV generado exitosamente'),
            action: SnackBarAction(
              label: 'Descargar',
              onPressed: () {
                // Aquí abrir URL o manejar descarga
                // launch(downloadUrl);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar CSV: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
