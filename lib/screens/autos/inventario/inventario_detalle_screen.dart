import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/models/autos/inventario_model.dart';
import 'package:stampcamera/providers/autos/inventario_provider.dart';
import 'package:stampcamera/screens/autos/inventario/imagenes_tab_widget.dart';
import 'package:stampcamera/screens/autos/inventario/inventario_tab_widget.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

class InventarioDetalleScreen extends ConsumerStatefulWidget {
  final int informacionUnidadId;

  const InventarioDetalleScreen({super.key, required this.informacionUnidadId});

  @override
  ConsumerState<InventarioDetalleScreen> createState() =>
      _InventarioDetalleScreenState();
}

class _InventarioDetalleScreenState
    extends ConsumerState<InventarioDetalleScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventarioProvider = ref.watch(
      inventarioDetalleProvider(widget.informacionUnidadId),
    );

    return inventarioProvider.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Cargando...'),
          backgroundColor: const Color(0xFF003B5C),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando detalle del inventario...'),
            ],
          ),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: const Color(0xFF003B5C),
          foregroundColor: Colors.white,
        ),
        body: ConnectionErrorScreen(
          error: error,
          onRetry: () => ref.refresh(
            inventarioDetalleProvider(widget.informacionUnidadId),
          ),
        ),
      ),
      data: (response) => _buildMainScreen(response),
    );
  }

  Widget _buildMainScreen(InventarioBaseResponse response) {
    final unidad = response.informacionUnidad;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${unidad.marca.marca} ${unidad.modelo}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              unidad.version,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF003B5C),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(
              icon: Icon(
                response.hasInventario
                    ? Icons.inventory_2
                    : Icons.inventory_2_outlined,
                size: 20,
              ),
              text: 'Inventario',
            ),
            Tab(
              icon: Icon(
                response.hasImages ? Icons.photo : Icons.photo_outlined,
                size: 20,
              ),
              text: 'Imágenes (${response.imageCount})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header con información de la unidad
          _buildHeaderInfo(response),

          // Contenido de las tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Inventario
                InventarioTabWidget(
                  response: response,
                  informacionUnidadId: widget.informacionUnidadId,
                ),

                // Tab 2: Imágenes
                ImagenesTabWidget(
                  response: response,
                  informacionUnidadId: widget.informacionUnidadId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(InventarioBaseResponse response) {
    final unidad = response.informacionUnidad;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Icono de la marca
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF003B5C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              unidad.marca.abrev,
              style: const TextStyle(
                color: Color(0xFF003B5C),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Información del embarque y cantidad
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.directions_boat,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        unidad.embarque,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${unidad.cantidadVins} unidades',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Badges de estado
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: response.hasInventario
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      response.hasInventario
                          ? Icons.check_circle
                          : Icons.pending,
                      size: 12,
                      color: response.hasInventario
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      response.hasInventario
                          ? 'Con Inventario'
                          : 'Sin Inventario',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: response.hasInventario
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              if (response.hasImages) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo, size: 12, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '${response.imageCount} fotos',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
