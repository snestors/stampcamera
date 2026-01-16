import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
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
}
