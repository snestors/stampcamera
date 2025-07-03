import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/models/autos/inventario_model.dart';
import 'package:stampcamera/providers/autos/inventario_provider.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class InventarioDetalleNaveScreen extends ConsumerStatefulWidget {
  final int naveId;

  const InventarioDetalleNaveScreen({super.key, required this.naveId});

  @override
  ConsumerState<InventarioDetalleNaveScreen> createState() =>
      _InventarioDetalleNaveScreenState();
}

class _InventarioDetalleNaveScreenState
    extends ConsumerState<InventarioDetalleNaveScreen> {
  final Map<String, bool> _expandedAgentes = {};
  final ScrollController _scrollController = ScrollController();
  bool _isHeaderVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Ocultar header cuando scroll > 50 pixels
    final shouldShowHeader = _scrollController.offset <= 50;

    if (shouldShowHeader != _isHeaderVisible) {
      setState(() {
        _isHeaderVisible = shouldShowHeader;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final naveProvider = ref.watch(inventariosByNaveProvider(widget.naveId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Inventarios'),
        backgroundColor: const Color(0xFF003B5C),
        foregroundColor: Colors.white,
      ),
      body: naveProvider.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando detalle...'),
            ],
          ),
        ),
        error: (error, stackTrace) => ConnectionErrorScreen(
          error: error,
          onRetry: () => ref.refresh(inventariosByNaveProvider(widget.naveId)),
        ),
        data: (naves) {
          if (naves.isEmpty) {
            return const Center(
              child: Text('No se encontraron datos para esta nave'),
            );
          }

          final nave = naves.first;
          return _buildDetalleContent(nave);
        },
      ),
    );
  }

  Widget _buildDetalleContent(InventarioNave nave) {
    // Agrupar modelos por agente y luego por marca
    final modelosPorAgenteYMarca =
        <String, Map<String, List<InventarioModelo>>>{};

    for (final modelo in nave.modelos) {
      final agente = modelo.agente.isNotEmpty ? modelo.agente : 'Sin Agente';
      final marca = modelo.marca;

      if (!modelosPorAgenteYMarca.containsKey(agente)) {
        modelosPorAgenteYMarca[agente] = {};
      }

      if (!modelosPorAgenteYMarca[agente]!.containsKey(marca)) {
        modelosPorAgenteYMarca[agente]![marca] = [];
      }

      modelosPorAgenteYMarca[agente]![marca]!.add(modelo);
    }

    return Column(
      children: [
        // Header animado que se oculta con scroll
        AnimatedContainer(
          duration: const Duration(milliseconds: 1800),
          curve: Curves.easeInOut,
          height: _isHeaderVisible ? null : 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 1800),
            opacity: _isHeaderVisible ? 1.0 : 0.0,
            child: _buildNaveHeader(nave),
          ),
        ),

        // Lista de agentes, marcas y modelos con ScrollController
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: modelosPorAgenteYMarca.entries.map((agenteEntry) {
              final agente = agenteEntry.key;
              final marcas = agenteEntry.value;
              return _buildAgenteSection(agente, marcas);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNaveHeader(InventarioNave nave) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF003B5C),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                nave.isSIC ? Icons.inventory : Icons.directions_boat,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nave.naveDescargaNombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildHeaderInfo('Puerto', nave.naveDescargaPuerto),
              const SizedBox(width: 20),
              _buildHeaderInfo('Rubro', nave.naveDescargaRubro),
            ],
          ),
          const SizedBox(height: 8),
          _buildHeaderInfo('Fecha Atraque', nave.naveDescargaFechaAtraque),
          const SizedBox(height: 16),

          // Totales
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTotalCounter(
                  'Total Unidades',
                  nave.totalUnidades.toString(),
                  Icons.inventory_2,
                ),
                if (nave.isFPR)
                  _buildTotalCounter(
                    'Descargadas',
                    nave.totalDescargadoPuerto.toString(),
                    Icons.anchor,
                  ),
                if (nave.isSIC)
                  _buildTotalCounter(
                    'Descargadas',
                    nave.totalDescargadoAlmacen.toString(),
                    Icons.warehouse,
                  ),
                _buildTotalCounter(
                  'Recepcionadas',
                  nave.totalDescargadoRecepcion.toString(),
                  Icons.login,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
        ),
        Text(
          value.isNotEmpty ? value : 'N/A',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCounter(String label, String count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAgenteSection(
    String agente,
    Map<String, List<InventarioModelo>> marcas,
  ) {
    final isExpanded = _expandedAgentes[agente] ?? false;

    // Calcular totales del agente
    final todoLosModelos = marcas.values.expand((modelos) => modelos).toList();
    final totalUnidades = todoLosModelos.fold<int>(
      0,
      (sum, modelo) => sum + modelo.cantidadUnidades,
    );
    final totalDescargadas = todoLosModelos.fold<int>(
      0,
      (sum, modelo) => sum + modelo.descargadoPuerto + modelo.descargadoAlmacen,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Header del agente
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF003B5C).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.business,
                color: Color(0xFF003B5C),
                size: 20,
              ),
            ),
            title: Text(
              agente,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              '$totalUnidades unidades • $totalDescargadas descargadas',
            ),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: () {
              setState(() {
                _expandedAgentes[agente] = !isExpanded;
              });
            },
          ),

          // Lista de marcas (expandible)
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                children: marcas.entries.map((marcaEntry) {
                  final marca = marcaEntry.key;
                  final modelos = marcaEntry.value;
                  return _buildMarcaSection(marca, modelos);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMarcaSection(String marca, List<InventarioModelo> modelos) {
    // Calcular totales de la marca
    final totalCantidad = modelos.fold<int>(
      0,
      (sum, modelo) => sum + modelo.cantidadUnidades,
    );
    final totalDescargado = modelos.fold<int>(
      0,
      (sum, modelo) => sum + modelo.descargadoPuerto + modelo.descargadoAlmacen,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header de la marca con botón compartir
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF003B5C),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    marca,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _shareReporte(marca, modelos),
                  icon: const Icon(Icons.share, color: Colors.white, size: 20),
                  tooltip: 'Compartir reporte',
                ),
              ],
            ),
          ),

          // Header de la tabla
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(color: Colors.grey.shade100),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'MODELO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'TOTAL',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Icon(
                    Icons.download,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),

          // Filas de modelos
          ...modelos.map((modelo) => _buildModeloRowSimple(modelo)).toList(),

          // Fila de totales
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '$totalCantidad',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '$totalDescargado',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeloRowSimple(InventarioModelo modelo) {
    final totalDescargadas = modelo.descargadoPuerto + modelo.descargadoAlmacen;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      childrenPadding: const EdgeInsets.only(left: 32, right: 16, bottom: 8),
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.white,
      iconColor: Colors.grey.shade600,
      collapsedIconColor: Colors.grey.shade600,
      title: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(modelo.modelo, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${modelo.cantidadUnidades}',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$totalDescargadas',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      children: [
        // Lista de versiones
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Versiones:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF003B5C),
                ),
              ),
              const SizedBox(height: 8),
              ...modelo.versiones
                  .map((version) => _buildVersionRowSimple(version))
                  .toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVersionRowSimple(InventarioVersion version) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Estado de inventario
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: version.inventario ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),

          // Información de la versión
          Expanded(
            child: Text(
              '${version.version} (${version.cantidadUnidades} unidades)',
              style: const TextStyle(fontSize: 12),
            ),
          ),

          // Badge de estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: version.inventario
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              version.inventario ? 'Con Inv.' : 'Sin Inv.',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: version.inventario
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Botón de acción
          GestureDetector(
            onTap: () =>
                _navigateToInventarioDetail(version.informacionUnidadId),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF003B5C).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFF003B5C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ MÉTODO SIMPLIFICADO PARA COMPARTIR - SIN NULL CHECK ERRORS
  Future<void> _shareReporte(
    String marca,
    List<InventarioModelo> modelos,
  ) async {
    final agente = modelos.isNotEmpty ? modelos.first.agente : 'Sin Agente';

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generando imagen...'),
            ],
          ),
        ),
      );

      // Crear widget temporal en Overlay para renderizar
      late OverlayEntry overlayEntry;
      final GlobalKey globalKey = GlobalKey();

      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: -1000, // Fuera de pantalla
          top: -1000,
          child: Material(
            child: RepaintBoundary(
              key: globalKey,
              child: _buildShareableWidget(marca, agente, modelos),
            ),
          ),
        ),
      );

      // Agregar al overlay
      Overlay.of(context).insert(overlayEntry);

      // Esperar a que se renderice
      await Future.delayed(const Duration(milliseconds: 100));

      // Capturar imagen
      final RenderRepaintBoundary boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      // Remover del overlay
      overlayEntry.remove();

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        // Guardar archivo temporal
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${directory.path}/reporte_${marca}_$timestamp.png');
        await file.writeAsBytes(pngBytes);

        // Cerrar loading
        if (mounted) Navigator.pop(context);

        // Compartir
        await SharePlus.instance.share(
          ShareParams(
            text: 'Reporte de Unidades: $marca - $agente',
            files: [XFile(file.path)],
          ),
        );

        // Mostrar éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Reporte generado y compartido'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      // Cerrar loading si hay error
      if (mounted) Navigator.pop(context);

      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al generar reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildShareableWidget(
    String marca,
    String agente,
    List<InventarioModelo> modelos,
  ) {
    // Calcular totales
    final totalCantidad = modelos.fold<int>(
      0,
      (sum, modelo) => sum + modelo.cantidadUnidades,
    );
    final totalDescargado = modelos.fold<int>(
      0,
      (sum, modelo) => sum + modelo.descargadoPuerto + modelo.descargadoAlmacen,
    );

    return Container(
      width: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF003B5C),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'ASTARA PERU S.A.C.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Agente: $agente',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Marca header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade100,
            child: Text(
              'MARCA: $marca',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),

          // Headers de tabla
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(color: Colors.grey.shade200),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'MODELO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'TOTAL',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'DESCARGADO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Filas de datos
          ...modelos.map((modelo) {
            final descargado =
                modelo.descargadoPuerto + modelo.descargadoAlmacen;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      modelo.modelo,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${modelo.cantidadUnidades}',
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '$descargado',
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          // Fila de totales
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '$totalCantidad',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '$totalDescargado',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Footer con fecha
          const SizedBox(height: 12),
          Text(
            'Generado: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _navigateToInventarioDetail(int informacionUnidadId) {
    print("Informacion Unidad $informacionUnidadId");
    context.push('/autos/inventario/detalle/$informacionUnidadId');
  }
}
