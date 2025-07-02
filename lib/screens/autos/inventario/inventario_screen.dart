import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/models/autos/inventario_model.dart';
import 'package:stampcamera/providers/autos/inventario_provider.dart';

// Importaciones del proyecto
import '../../../widgets/connection_error_screen.dart';

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
          _buildSearchBar(),

          Expanded(child: _buildResultsList(inventariosAsync, notifier)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
                    ref.read(inventarioBaseProvider.notifier).clearSearch();
                    _searchFocusNode.unfocus();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: (value) {
          setState(() {});
          if (value.trim().isEmpty) {
            ref.read(inventarioBaseProvider.notifier).clearSearch();
          } else {
            ref.read(inventarioBaseProvider.notifier).debouncedSearch(value);
          }
        },
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            ref.read(inventarioBaseProvider.notifier).search(value);
            _searchFocusNode.unfocus();
          }
        },
      ),
    );
  }

  Widget _buildResultsList(
    AsyncValue<List<InventarioNave>> inventariosAsync,
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
      error: (error, stackTrace) => ConnectionErrorScreen(
        error: error,
        onRetry: () => notifier.refresh(),
      ),
      data: (naves) => _buildDataState(naves, notifier),
    );
  }

  Widget _buildDataState(
    List<InventarioNave> naves,
    InventarioBaseNotifier notifier,
  ) {
    if (naves.isEmpty) {
      return _buildEmptyState(notifier);
    }

    final showLoadMoreIndicator = notifier.hasNextPage && !notifier.isSearching;

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: naves.length + (showLoadMoreIndicator ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < naves.length) {
            final nave = naves[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _buildNaveCard(nave),
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

  Widget _buildNaveCard(InventarioNave nave) {
    return Card(
      child: ListTile(
        title: Row(
          children: [
            Icon(
              nave.isSIC ? Icons.inventory : Icons.directions_boat,
              color: nave.isSIC ? Colors.orange.shade700 : Colors.blue.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                nave.naveDescargaNombre,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (nave.naveDescargaPuerto.isNotEmpty)
                Text(
                  'Puerto: ${nave.naveDescargaPuerto}',
                  style: const TextStyle(fontSize: 12),
                ),
              if (nave.naveDescargaRubro.isNotEmpty)
                Text(
                  'Rubro: ${nave.naveDescargaRubro}',
                  style: const TextStyle(fontSize: 12),
                ),
              if (nave.naveDescargaFechaAtraque.isNotEmpty)
                Text(
                  'Atraque: ${nave.naveDescargaFechaAtraque}',
                  style: const TextStyle(fontSize: 12),
                ),
              const SizedBox(height: 4),

              // Fila principal con total
              Row(
                children: [
                  Text(
                    '${nave.totalUnidades} unidades',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Fila con contadores específicos usando getters del modelo
              Row(
                children: [
                  // Mostrar descargadas según el tipo de rubro
                  if (nave.isFPR && nave.totalDescargadoPuerto > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${nave.totalDescargadoPuerto} descargadas',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],

                  if (nave.isSIC && nave.totalDescargadoAlmacen > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${nave.totalDescargadoAlmacen} descargadas',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],

                  // Recepcionadas - para TODOS
                  if (nave.totalDescargadoRecepcion > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${nave.totalDescargadoRecepcion} recepcionadas',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade700,
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
        onTap: () => _navigateToNaveDetail(nave.naveDescargaId),
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
            ElevatedButton.icon(
              onPressed: () => notifier.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // MÉTODOS DE ACCIÓN
  // ============================================================================

  void _navigateToNaveDetail(int naveId) {
    print("To inventario Detalle ID: $naveId");
    context.push('/autos/inventario/nave/${naveId.toString()}');
  }

  // ============================================================================
  // MÉTODOS DE FILTROS
  // ============================================================================
}
