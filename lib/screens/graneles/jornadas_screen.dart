// =============================================================================
// PANTALLA RESUMEN POR JORNADAS
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/graneles/graneles_provider.dart';
import 'package:stampcamera/models/graneles/servicio_granel_model.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

class JornadasScreen extends ConsumerStatefulWidget {
  final int servicioId;

  const JornadasScreen({super.key, required this.servicioId});

  @override
  ConsumerState<JornadasScreen> createState() => _JornadasScreenState();
}

class _JornadasScreenState extends ConsumerState<JornadasScreen> {
  String? _productoFiltro;
  String? _tipoOperacion;

  ResumenJornadasParams get _params => ResumenJornadasParams(
        servicioId: widget.servicioId,
        producto: _productoFiltro,
        tipoOperacion: _tipoOperacion,
      );

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(servicioDashboardProvider(widget.servicioId));
    final jornadasAsync = ref.watch(resumenJornadasProvider(_params));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Resumen por Jornada',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(resumenJornadasProvider(_params));
              ref.invalidate(servicioDashboardProvider(widget.servicioId));
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => ConnectionErrorScreen(
          error: error,
          onRetry: () => ref.invalidate(servicioDashboardProvider(widget.servicioId)),
        ),
        data: (dashboard) => Column(
          children: [
            // Header con info del servicio
            _buildServiceHeader(dashboard.servicio),

            // Filtros
            _buildFilters(dashboard.productos),

            // Tabla de jornadas
            Expanded(
              child: jornadasAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, _) => ConnectionErrorScreen(
                  error: error,
                  onRetry: () => ref.invalidate(resumenJornadasProvider(_params)),
                ),
                data: (resumen) => resumen.hasData
                    ? _JornadasTableView(resumen: resumen)
                    : const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Sin datos de jornadas',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceHeader(DashboardServicioInfo servicio) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceM,
        vertical: DesignTokens.spaceS,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_boat, color: Colors.white, size: 20),
          const SizedBox(width: DesignTokens.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  servicio.naveNombre ?? 'Sin nave',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (servicio.consignatario != null)
                  Text(
                    servicio.consignatario!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceS,
              vertical: DesignTokens.spaceXS,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Text(
              servicio.codigo,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(List<DashboardProducto> productos) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceM,
        vertical: DesignTokens.spaceS,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: Wrap(
        spacing: DesignTokens.spaceS,
        runSpacing: DesignTokens.spaceS,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Filtro producto
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Producto:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: DesignTokens.spaceXS),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _productoFiltro ?? '',
                    isDense: true,
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Todos')),
                      ...productos.map((p) => DropdownMenuItem(
                            value: p.producto,
                            child: Text(p.producto),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _productoFiltro = value?.isEmpty == true ? null : value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),

          // Filtro tipo operacion
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Operacion:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: DesignTokens.spaceXS),
              _FilterChip(
                label: 'Ambos',
                selected: _tipoOperacion == null,
                onSelected: () => setState(() => _tipoOperacion = null),
              ),
              const SizedBox(width: DesignTokens.spaceXS),
              _FilterChip(
                label: 'Directa',
                selected: _tipoOperacion == 'directa',
                onSelected: () => setState(() => _tipoOperacion = 'directa'),
              ),
              const SizedBox(width: DesignTokens.spaceXS),
              _FilterChip(
                label: 'Silos',
                selected: _tipoOperacion == 'silos',
                onSelected: () => setState(() => _tipoOperacion = 'silos'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CHIP DE FILTRO
// =============================================================================

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderMedium,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TABLA DE JORNADAS - SCROLL BIDIRECCIONAL
// =============================================================================

class _JornadasTableView extends StatelessWidget {
  final ResumenJornadas resumen;
  static final _nf = NumberFormat('#,##0.000', 'es');

  const _JornadasTableView({required this.resumen});

  @override
  Widget build(BuildContext context) {
    final cabBodega = resumen.cabecerasBodega;
    final cabAlmacen = resumen.cabecerasAlmacen;

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _buildTable(cabBodega, cabAlmacen),
      ),
    );
  }

  Widget _buildTable(
    List<JornadaCabeceraBodega> cabBodega,
    List<JornadaCabeceraAlmacen> cabAlmacen,
  ) {
    // Colores para secciones
    const descargaColor = Color(0xFF0284C7); // sky-600
    const descargaLightBg = Color(0xFFF0F9FF); // sky-50
    const descargaTotalBg = Color(0xFFE0F2FE); // sky-100
    const despachoColor = Color(0xFFF97316); // orange-500
    const despachoLightBg = Color(0xFFFFF7ED); // orange-50
    const despachoTotalBg = Color(0xFFFFEDD5); // orange-100

    final colsBodega = cabBodega.length + (cabBodega.isNotEmpty ? 1 : 0);
    final colsAlmacen = cabAlmacen.length + (cabAlmacen.isNotEmpty ? 1 : 0);

    const double colWidth = 110.0;
    const double jornadaWidth = 120.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ===== ROW 1: Section headers — Row limpio sin bordes internos =====
        Row(
          children: [
            Container(
              width: jornadaWidth,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                border: Border(
                  top: BorderSide(color: AppColors.borderLight, width: 0.5),
                  left: BorderSide(color: AppColors.borderLight, width: 0.5),
                  bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
                  right: BorderSide(color: AppColors.borderLight, width: 0.5),
                ),
              ),
              child: const Text('Jornada', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ),
            if (cabBodega.isNotEmpty)
              Container(
                width: colWidth * colsBodega,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: descargaColor,
                  border: Border(
                    top: const BorderSide(color: descargaColor, width: 0.5),
                    bottom: const BorderSide(color: descargaColor, width: 0.5),
                    right: BorderSide(color: cabAlmacen.isNotEmpty ? Colors.white24 : descargaColor, width: 1),
                  ),
                ),
                alignment: Alignment.center,
                child: const Text('DESCARGA DE NAVE', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            if (cabAlmacen.isNotEmpty)
              Container(
                width: colWidth * colsAlmacen,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: const BoxDecoration(
                  color: despachoColor,
                  border: Border(
                    top: BorderSide(color: despachoColor, width: 0.5),
                    bottom: BorderSide(color: despachoColor, width: 0.5),
                    right: BorderSide(color: despachoColor, width: 0.5),
                  ),
                ),
                alignment: Alignment.center,
                child: const Text('DESPACHO A ALMACENES', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
          ],
        ),
        // ===== TABLE: Rows 2+ =====
        Table(
          columnWidths: {
            0: const FixedColumnWidth(jornadaWidth),
            for (int i = 1; i <= colsBodega + colsAlmacen; i++)
              i: const FixedColumnWidth(colWidth),
          },
          border: TableBorder.all(
            color: AppColors.borderLight,
            width: 0.5,
          ),
          children: [
            // ===== ROW 2: Product headers with manifest =====
        TableRow(
          children: [
            _headerCell('', color: const Color(0xFFF9FAFB)),
            ...cabBodega.map((c) => _productHeaderCell(
                  c.producto,
                  '${_nf.format(c.pesoManifestado)} TM',
                  c.bagsManifestados,
                  descargaLightBg,
                )),
            if (cabBodega.isNotEmpty)
              _productHeaderCell(
                'Total Manif.',
                '${_nf.format(resumen.totalManifestadoBodega)} TM',
                resumen.totalBagsManifestadosBodega,
                descargaTotalBg,
                bold: true,
              ),
            ...cabAlmacen.map((c) => _productHeaderCell(
                  c.producto,
                  '${_nf.format(c.pesoManifestado)} TM',
                  c.bagsManifestados,
                  despachoLightBg,
                )),
            if (cabAlmacen.isNotEmpty)
              _productHeaderCell(
                'Total Manif.',
                '${_nf.format(resumen.totalManifestadoAlmacen)} TM',
                resumen.totalBagsManifestadosAlmacen,
                despachoTotalBg,
                bold: true,
              ),
          ],
        ),

        // ===== ROW 3: Bodega/Almacen names =====
        TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade400, width: 1.5),
            ),
          ),
          children: [
            _headerCell('', color: const Color(0xFFF9FAFB)),
            ...cabBodega.map((c) => _nameHeaderCell(c.bodega, descargaLightBg)),
            if (cabBodega.isNotEmpty)
              _nameHeaderCell('Total Descargado', descargaTotalBg, bold: true),
            ...cabAlmacen.map((c) => _nameHeaderCell(c.almacen, despachoLightBg)),
            if (cabAlmacen.isNotEmpty)
              _nameHeaderCell('Total Despachado', despachoTotalBg, bold: true),
          ],
        ),

        // ===== JORNADA ROWS =====
        ...resumen.jornadas.map((j) => TableRow(
              children: [
                // Jornada label
                _jornadaLabelCell(j),
                // Bodegas
                ...j.productosBodega.map((pb) => _bodegaDataCell(pb)),
                if (cabBodega.isNotEmpty) _bodegaTotalCell(j, descargaLightBg),
                // Almacenes
                ...j.productosAlmacen.map((pa) => _almacenDataCell(pa)),
                if (cabAlmacen.isNotEmpty) _almacenTotalCell(j, despachoLightBg),
              ],
            )),

        // ===== TOTALES GENERALES =====
        TableRow(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6), // gray-100
            border: Border(
              top: BorderSide(color: Colors.grey.shade400, width: 2),
            ),
          ),
          children: [
            _totalLabelCell('Totales Generales'),
            ...resumen.totalesBodega.map((t) => _totalDataCell(
                  '${_nf.format(t.totalPeso)} TM',
                  '${t.totalViajes} viajes',
                  t.totalBags,
                )),
            if (cabBodega.isNotEmpty)
              _totalDataCell(
                '${_nf.format(resumen.totalPesoBodega)} TM',
                '${resumen.totalViajesBodega} viajes',
                resumen.totalBagsBodega,
                bgColor: descargaTotalBg.withValues(alpha: 0.5),
              ),
            ...resumen.totalesAlmacen.map((t) => _totalDataCell(
                  '${_nf.format(t.totalPeso)} TM',
                  '${t.totalViajes} viajes',
                  t.totalBags,
                )),
            if (cabAlmacen.isNotEmpty)
              _totalDataCell(
                '${_nf.format(resumen.totalPesoAlmacen)} TM',
                '${resumen.totalViajesAlmacen} viajes',
                resumen.totalBagsAlmacen,
                bgColor: despachoTotalBg.withValues(alpha: 0.5),
              ),
          ],
        ),

        // ===== SALDOS =====
        TableRow(
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB), // gray-200
            border: Border(
              top: BorderSide(color: Colors.grey.shade400, width: 1),
            ),
          ),
          children: [
            _totalLabelCell('Saldos'),
            ...resumen.saldosBodega.map((s) => _saldoCell(s.saldo, s.saldoBags)),
            if (cabBodega.isNotEmpty)
              _saldoCell(
                resumen.saldoTotalBodega,
                resumen.saldoTotalBagsBodega,
                bgColor: descargaTotalBg.withValues(alpha: 0.3),
              ),
            ...resumen.saldosAlmacen.map((s) => _saldoCell(s.saldo, s.saldoBags)),
            if (cabAlmacen.isNotEmpty)
              _saldoCell(
                resumen.saldoTotalAlmacen,
                resumen.saldoTotalBagsAlmacen,
                bgColor: despachoTotalBg.withValues(alpha: 0.3),
              ),
          ],
        ),
      ],
    ),
      ],
    );
  }

  // ===========================================================================
  // CELL BUILDERS
  // ===========================================================================

  Widget _headerCell(String text, {Color? color}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: color ?? AppColors.surface,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _productHeaderCell(
    String producto,
    String manifest,
    int bags,
    Color bgColor, {
    bool bold = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      color: bgColor,
      child: Column(
        children: [
          Text(
            producto,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            manifest,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          if (bags > 0)
            Text(
              '$bags bags',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textLight,
              ),
            ),
        ],
      ),
    );
  }

  Widget _nameHeaderCell(String name, Color bgColor, {bool bold = false}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      color: bgColor,
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _jornadaLabelCell(JornadaResumen j) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            j.jornada,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'J${j.nJornada} - ${j.turno}',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bodegaDataCell(JornadaProductoBodega pb) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Column(
        children: [
          Text(
            '${_nf.format(pb.peso)} TM',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Muelle: ${pb.viajesMuelle}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
          if (pb.pesoSilos > 0)
            Text(
              'Silos: ${_nf.format(pb.pesoSilos)} TM',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFFD97706), // amber-600
                fontWeight: FontWeight.w500,
              ),
            ),
          if (pb.viajesSilos > 0)
            Text(
              'V.Silos: ${pb.viajesSilos}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFFD97706),
              ),
            ),
          if (pb.bags > 0)
            Text(
              '${pb.bags} bags',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF7C3AED), // purple-600
              ),
            ),
        ],
      ),
    );
  }

  Widget _bodegaTotalCell(JornadaResumen j, Color bgColor) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      color: bgColor.withValues(alpha: 0.4),
      child: Column(
        children: [
          Text(
            '${_nf.format(j.totalPesoBodega)} TM',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Muelle: ${j.totalViajesMuelleBodega}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (j.totalViajesSilosBodega > 0)
            Text(
              'Silos: ${j.totalViajesSilosBodega}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFFD97706),
                fontWeight: FontWeight.w500,
              ),
            ),
          if (j.totalBagsBodega > 0)
            Text(
              '${j.totalBagsBodega} bags',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF7C3AED),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _almacenDataCell(JornadaProductoAlmacen pa) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Column(
        children: [
          Text(
            '${_nf.format(pa.peso)} TM',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '${pa.viajes} viajes',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
          if (pa.bags > 0)
            Text(
              '${pa.bags} bags',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF7C3AED),
              ),
            ),
        ],
      ),
    );
  }

  Widget _almacenTotalCell(JornadaResumen j, Color bgColor) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      color: bgColor.withValues(alpha: 0.4),
      child: Column(
        children: [
          Text(
            '${_nf.format(j.totalPesoAlmacen)} TM',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '${j.totalViajesAlmacen} viajes',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (j.totalBagsAlmacen > 0)
            Text(
              '${j.totalBagsAlmacen} bags',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF7C3AED),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _totalLabelCell(String text) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _totalDataCell(
    String peso,
    String viajes,
    int bags, {
    Color? bgColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      color: bgColor,
      child: Column(
        children: [
          Text(
            peso,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            viajes,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
          ),
          if (bags > 0)
            Text(
              '$bags bags',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF7C3AED),
              ),
            ),
        ],
      ),
    );
  }

  Widget _saldoCell(double saldo, int saldoBags, {Color? bgColor}) {
    final isNegative = saldo < 0;
    final color = isNegative ? AppColors.error : AppColors.success;

    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      color: bgColor,
      child: Column(
        children: [
          Text(
            '${_nf.format(saldo)} TM',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (saldoBags != 0)
            Text(
              '$saldoBags bags',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}
