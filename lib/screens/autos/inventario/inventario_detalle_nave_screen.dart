import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/models/autos/inventario_model.dart';
import 'package:stampcamera/providers/autos/inventario_provider.dart';
import 'package:stampcamera/providers/auth_provider.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';
import 'package:stampcamera/widgets/naves/editar_nave_bottom_sheet.dart';
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

  @override
  void initState() {
    super.initState();
    // Remover invalidación automática - solo manual cuando sea necesario
  }

  @override
  Widget build(BuildContext context) {
    final naveProvider = ref.watch(inventariosByNaveProvider(widget.naveId));
    final user = ref.watch(authProvider).valueOrNull?.user;
    final puedeEditar = user?.canChangeNaveStatus ?? false;

    // El nombre real de la nave lo obtenemos del data (si hay); como fallback,
    // mostramos el ID hasta que cargue.
    final naveNombre = naveProvider.whenOrNull(
          data: (naves) => naves.isNotEmpty ? naves.first.naveDescargaNombre : null,
        ) ??
        'Nave ${widget.naveId}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Inventarios'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (puedeEditar)
            IconButton(
              icon: const Icon(Icons.edit_calendar),
              onPressed: () => _abrirEditarNave(naveNombre),
              tooltip: 'Editar estado de nave',
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Descargar pendientes',
            onSelected: (tipo) => _descargarPendientes(tipo, naveNombre),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'pedeteo',
                child: Row(
                  children: [
                    Icon(Icons.pending_actions, size: 18, color: AppColors.warning),
                    SizedBox(width: 8),
                    Text('Faltan pedetear (Excel)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'recepcion',
                child: Row(
                  children: [
                    Icon(Icons.login, size: 18, color: AppColors.recepcion),
                    SizedBox(width: 8),
                    Text('Faltan recepcionar (Excel)'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(inventariosByNaveProvider(widget.naveId)),
            tooltip: 'Actualizar datos',
          ),
        ],
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
          onRetry: () => ref.invalidate(inventariosByNaveProvider(widget.naveId)),
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header simplificado incluido en el scroll
        _buildNaveHeader(nave),
        
        const SizedBox(height: 16),
        
        // Lista de agentes, marcas y modelos
        ...modelosPorAgenteYMarca.entries.map((agenteEntry) {
          final agente = agenteEntry.key;
          final marcas = agenteEntry.value;
          return _buildAgenteSection(agente, marcas, nave.isFPR);
        }),
      ],
    );
  }

  Widget _buildNaveHeader(InventarioNave nave) {
    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título compacto
            Row(
              children: [
                Icon(
                  nave.isSIC ? Icons.inventory : Icons.directions_boat,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nave.naveDescargaNombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (nave.naveDescargaPuerto.isNotEmpty)
                        Text(
                          'Puerto: ${nave.naveDescargaPuerto}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      if (nave.naveDescargaFechaAtraque.isNotEmpty)
                        Text(
                          'Atraque: ${nave.naveDescargaFechaAtraque}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Totales compactos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCompactCounter(
                  'Total',
                  nave.totalUnidades.toString(),
                  Icons.inventory_2,
                ),
                if (nave.isFPR)
                  _buildCompactCounter(
                    'Puerto',
                    nave.totalDescargadoPuerto.toString(),
                    Icons.anchor,
                  ),
                if (nave.isSIC)
                  _buildCompactCounter(
                    'Almacén',
                    nave.totalDescargadoAlmacen.toString(),
                    Icons.warehouse,
                  ),
                _buildCompactCounter(
                  'Recep.',
                  nave.totalDescargadoRecepcion.toString(),
                  Icons.login,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCounter(String label, String count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAgenteSection(
    String agente,
    Map<String, List<InventarioModelo>> marcas,
    bool isFPR,
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
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.business,
                color: AppColors.primary,
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
                  return _buildMarcaSection(marca, modelos, isFPR);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMarcaSection(
    String marca,
    List<InventarioModelo> modelos,
    bool isFPR,
  ) {
    // Calcular totales de la marca
    final totalCantidad = modelos.fold<int>(
      0,
      (sum, modelo) => sum + modelo.cantidadUnidades,
    );
    final totalDescargado = modelos.fold<int>(
      0,
      (sum, modelo) => sum + modelo.descargadoPuerto + modelo.descargadoAlmacen,
    );
    final totalRecepcion = modelos.fold<int>(
      0,
      (sum, modelo) => sum + modelo.descargadoRecepcion,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Column(
        children: [
          // Header de la marca con botón compartir
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
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
            decoration: const BoxDecoration(color: AppColors.surface),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'MODELO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'TOTAL',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'DESC.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'RECEP.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: AppColors.recepcion,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Spacer(),
              ],
            ),
          ),

          // Filas de modelos
          ...modelos.map((modelo) => _buildModeloRowSimple(modelo, isFPR)),

          // Fila de totales
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.neutral, width: 1),
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
                Expanded(
                  flex: 2,
                  child: Text(
                    '$totalRecepcion',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.recepcion,
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

  Widget _buildModeloRowSimple(InventarioModelo modelo, bool isFPR) {
    final totalDescargadas = modelo.descargadoPuerto + modelo.descargadoAlmacen;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      childrenPadding: const EdgeInsets.only(left: 32, right: 16, bottom: 8),
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.white,
      iconColor: AppColors.textSecondary,
      collapsedIconColor: AppColors.textSecondary,
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
          Expanded(
            flex: 2,
            child: Text(
              '${modelo.descargadoRecepcion}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.recepcion,
              ),
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
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Versiones:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              ...modelo.versiones.map(
                (version) => _buildVersionRowSimple(version, isFPR),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVersionRowSimple(InventarioVersion version, bool isFPR) {
    final descargadas = version.descargadas(isFPR: isFPR);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToInventarioDetail(version.informacionUnidadId),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: version.inventario
                  ? AppColors.success.withValues(alpha: 0.08)
                  : AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(
                color: version.inventario
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.warning.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                // Estado de inventario
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: version.inventario ? AppColors.success : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),

                // Información de la versión
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        version.version,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$descargadas/${version.cantidadUnidades} descargadas • ${version.descargadoRecepcion} recep. • ${version.inventario ? "Inventariado" : "Pendiente"}',
                        style: const TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Texto + flecha de acción
                const Text(
                  'Ver',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ MÉTODO SIMPLIFICADO PARA COMPARTIR - SIN NULL CHECK ERRORS
  Future<void> _shareReporte(
    String marca,
    List<InventarioModelo> modelos,
  ) async {
    final agente = modelos.isNotEmpty ? modelos.first.agente : 'Sin Agente';
    final cliente = modelos.isNotEmpty ? modelos.first.cliente : 'Sin Cliente';

    try {
      // Mostrar loading
      AppDialog.loading(context, message: 'Generando imagen...');

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
              child: _buildShareableWidget(marca, cliente, agente, modelos),
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
        if (mounted) AppDialog.closeLoading(context);

        // Compartir
        await SharePlus.instance.share(
          ShareParams(
            text: 'Reporte de Unidades: $marca - $cliente',
            files: [XFile(file.path)],
          ),
        );

        // Mostrar éxito
        if (mounted) {
          AppSnackBar.success(context, 'Reporte generado y compartido');
        }
      }
    } catch (e) {
      // Cerrar loading si hay error
      if (mounted) AppDialog.closeLoading(context);

      // Mostrar error
      if (mounted) {
        AppSnackBar.error(context, 'Error al generar reporte: $e');
      }
    }
  }

  Widget _buildShareableWidget(
    String marca,
    String cliente,
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
    final totalRecepcion = modelos.fold<int>(
      0,
      (sum, modelo) => sum + modelo.descargadoRecepcion,
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
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Column(
              children: [
                Text(
                  cliente.toUpperCase(),
                  style: const TextStyle(
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
                Expanded(
                  flex: 2,
                  child: Text(
                    'RECEPCIÓN',
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
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${modelo.descargadoRecepcion}',
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }),

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
                Expanded(
                  flex: 2,
                  child: Text(
                    '$totalRecepcion',
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
          Builder(builder: (_) {
            final ahora = nowLima();
            return Text(
              'Generado: ${ahora.day}/${ahora.month}/${ahora.year} ${ahora.hour}:${ahora.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
            );
          }),
        ],
      ),
    );
  }

  /// Descarga el Excel de pendientes (pedeteo o recepción) y lo comparte.
  /// Requiere endpoint backend: /api/v1/autos/registro-general/export-pendientes/
  Future<void> _descargarPendientes(String tipo, String naveNombre) async {
    final label = tipo == 'pedeteo' ? 'pedeteo' : 'recepción';

    try {
      AppDialog.loading(context, message: 'Generando Excel de pendientes...');

      final service = ref.read(inventarioBaseServiceProvider);
      final bytes = await service.descargarPendientesExcel(
        naveId: widget.naveId,
        tipo: tipo,
      );

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File(
        '${directory.path}/pendientes_${tipo}_nave${widget.naveId}_$timestamp.xlsx',
      );
      await file.writeAsBytes(bytes);

      if (mounted) AppDialog.closeLoading(context);

      await SharePlus.instance.share(
        ShareParams(
          text: 'Pendientes de $label - $naveNombre',
          files: [XFile(file.path)],
        ),
      );

      if (mounted) {
        AppSnackBar.success(context, 'Excel de pendientes generado');
      }
    } catch (e) {
      if (mounted) AppDialog.closeLoading(context);
      if (mounted) {
        AppSnackBar.error(context, 'Error al descargar pendientes: $e');
      }
    }
  }

  void _navigateToInventarioDetail(int informacionUnidadId) {
    context.push('/autos/inventario/detalle/$informacionUnidadId');
  }

  Future<void> _abrirEditarNave(String naveNombre) async {
    final updated = await showEditarNaveBottomSheet(
      context,
      naveId: widget.naveId,
      naveNombre: naveNombre,
    );
    if (updated == true) {
      ref.invalidate(inventariosByNaveProvider(widget.naveId));
    }
  }
}
