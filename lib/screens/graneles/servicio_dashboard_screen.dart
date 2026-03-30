// =============================================================================
// PANTALLA DASHBOARD DE SERVICIO GRANEL
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/graneles/graneles_provider.dart';
import 'package:stampcamera/models/graneles/servicio_granel_model.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

class ServicioDashboardScreen extends ConsumerWidget {
  final int servicioId;

  const ServicioDashboardScreen({super.key, required this.servicioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(servicioDashboardProvider(servicioId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: DesignTokens.fontSizeL,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(servicioDashboardProvider(servicioId)),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => ConnectionErrorScreen(
          error: error,
          onRetry: () => ref.invalidate(servicioDashboardProvider(servicioId)),
        ),
        data: (dashboard) => _DashboardContent(
          dashboard: dashboard,
          onRefresh: () => ref.invalidate(servicioDashboardProvider(servicioId)),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final ServicioDashboard dashboard;
  final VoidCallback onRefresh;

  const _DashboardContent({
    required this.dashboard,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del servicio
            _buildHeader(),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Boton Jornadas
                  _buildJornadasButton(context),
                  const SizedBox(height: DesignTokens.spaceL),

                  // KPIs principales
                  _buildKpisGrid(),
                  const SizedBox(height: DesignTokens.spaceL),

                  // Progreso general
                  _buildProgressCard(),
                  const SizedBox(height: DesignTokens.spaceL),

                  // Viajes
                  _buildViajesCard(),
                  const SizedBox(height: DesignTokens.spaceL),

                  // Silos (si hay datos)
                  if (dashboard.silos.totalViajes > 0) ...[
                    _buildSilosCard(),
                    const SizedBox(height: DesignTokens.spaceL),
                  ],

                  // Descarga por Bodega de Nave
                  _buildBodegasCard(),
                  const SizedBox(height: DesignTokens.spaceL),

                  // Productos con distribuciones
                  if (dashboard.productos.isNotEmpty) ...[
                    _buildSectionTitle('Detalle por Producto'),
                    const SizedBox(height: DesignTokens.spaceM),
                    ...dashboard.productos.map(
                      (producto) => _ProductoExpandableCard(producto: producto),
                    ),
                  ],

                  const SizedBox(height: DesignTokens.spaceXL),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final servicio = dashboard.servicio;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spaceM),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Código y estado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceS,
                  vertical: DesignTokens.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Text(
                  servicio.codigo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: DesignTokens.fontSizeS,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.spaceS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceS,
                  vertical: DesignTokens.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: servicio.cierreServicio ? AppColors.success : AppColors.warning,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      servicio.cierreServicio ? Icons.check_circle : Icons.schedule,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: DesignTokens.spaceXS),
                    Text(
                      servicio.cierreServicio ? 'CERRADO' : 'EN PROCESO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: DesignTokens.fontSizeXS,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceM),

          // Nave
          Row(
            children: [
              const Icon(Icons.directions_boat, color: Colors.white, size: 24),
              const SizedBox(width: DesignTokens.spaceS),
              Expanded(
                child: Text(
                  servicio.naveNombre ?? 'Sin nave',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: DesignTokens.fontSizeL,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceS),

          // Info adicional
          Wrap(
            spacing: DesignTokens.spaceM,
            runSpacing: DesignTokens.spaceXS,
            children: [
              if (servicio.consignatario != null)
                _HeaderChip(icon: Icons.business, text: servicio.consignatario!),
              if (servicio.puerto != null)
                _HeaderChip(icon: Icons.location_on, text: servicio.puerto!),
              if (servicio.fechaAtraque != null)
                _HeaderChip(
                  icon: Icons.calendar_today,
                  text: dateFormat.format(toLima(servicio.fechaAtraque!)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpisGrid() {
    final kpis = dashboard.kpis;
    final numberFormat = NumberFormat('#,##0.00', 'es');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Resumen de Carga'),
        const SizedBox(height: DesignTokens.spaceM),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: 'Manifestado',
                value: numberFormat.format(kpis.totalManifestado),
                unit: 'TM',
                icon: Icons.inventory_2_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: DesignTokens.spaceS),
            Expanded(
              child: _KpiCard(
                title: 'Descargado',
                value: numberFormat.format(kpis.totalDescargado),
                unit: 'TM',
                percentage: kpis.porcentajeDescarga,
                icon: Icons.download_outlined,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spaceS),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: 'Despachado',
                value: numberFormat.format(kpis.totalDespachado),
                unit: 'TM',
                percentage: kpis.porcentajeDespacho,
                icon: Icons.local_shipping_outlined,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: DesignTokens.spaceS),
            Expanded(
              child: _KpiCard(
                title: 'Saldo',
                value: numberFormat.format(kpis.saldoDescarga),
                unit: 'TM',
                icon: Icons.pending_actions_outlined,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    final kpis = dashboard.kpis;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, size: 20, color: AppColors.primary),
              SizedBox(width: DesignTokens.spaceS),
              Text(
                'Progreso General',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceL),
          _ProgressRow(
            label: 'Descarga de Nave',
            percentage: kpis.porcentajeDescarga,
            color: AppColors.success,
          ),
          const SizedBox(height: DesignTokens.spaceM),
          _ProgressRow(
            label: 'Despacho a Almacén',
            percentage: kpis.porcentajeDespacho,
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildViajesCard() {
    final kpis = dashboard.kpis;
    final numberFormat = NumberFormat('#,##0', 'es');

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.route, size: 20, color: AppColors.primary),
              SizedBox(width: DesignTokens.spaceS),
              Text(
                'Viajes Registrados',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceM),
          Row(
            children: [
              Expanded(
                child: _ViajeItem(
                  icon: Icons.receipt_long,
                  label: 'Muelle',
                  value: numberFormat.format(kpis.viajesMuelle),
                  color: AppColors.primary,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: AppColors.neutral.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _ViajeItem(
                  icon: Icons.scale,
                  label: 'Balanza',
                  value: numberFormat.format(kpis.viajesBalanza),
                  color: AppColors.secondary,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: AppColors.neutral.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _ViajeItem(
                  icon: Icons.warehouse,
                  label: 'Almacén',
                  value: numberFormat.format(kpis.viajesAlmacen),
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSilosCard() {
    final silos = dashboard.silos;
    final numberFormat = NumberFormat('#,##0.00', 'es');
    final intFormat = NumberFormat('#,##0', 'es');

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.storage, size: 20, color: AppColors.secondary),
              SizedBox(width: DesignTokens.spaceS),
              Text(
                'Silos',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceM),

          // Totales
          Row(
            children: [
              Expanded(
                child: _SilosSummaryItem(
                  label: 'Peso Total',
                  value: '${numberFormat.format(silos.totalPeso)} TM',
                  color: AppColors.secondary,
                ),
              ),
              Expanded(
                child: _SilosSummaryItem(
                  label: 'Bags',
                  value: intFormat.format(silos.totalBags),
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _SilosSummaryItem(
                  label: 'Viajes',
                  value: intFormat.format(silos.totalViajes),
                  color: AppColors.accent,
                ),
              ),
            ],
          ),

          // Por producto
          if (silos.porProducto.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spaceM),
            Divider(color: AppColors.neutral.withValues(alpha: 0.2)),
            const SizedBox(height: DesignTokens.spaceS),
            const Text(
              'Por Producto',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: DesignTokens.spaceS),
            ...silos.porProducto.map((p) => _SilosProductoRow(
                  producto: p,
                  numberFormat: numberFormat,
                  intFormat: intFormat,
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildBodegasCard() {
    final bodegas = dashboard.bodegas;
    final numberFormat = NumberFormat('#,##0.00', 'es');
    final intFormat = NumberFormat('#,##0', 'es');

    // Calcular porcentaje total
    final porcentajeTotal = bodegas.totalManifestado > 0
        ? (bodegas.totalDescargado / bodegas.totalManifestado * 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_boat, size: 20, color: AppColors.primary),
              SizedBox(width: DesignTokens.spaceS),
              Expanded(
                child: Text(
                  'Descarga por Bodega',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceM),

          // Totales
          Row(
            children: [
              Expanded(
                child: _BodegaSummaryItem(
                  label: 'Manifestado',
                  value: '${numberFormat.format(bodegas.totalManifestado)} TM',
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _BodegaSummaryItem(
                  label: 'Descargado',
                  value: '${numberFormat.format(bodegas.totalDescargado)} TM',
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _BodegaSummaryItem(
                  label: 'Avance',
                  value: '${porcentajeTotal.toStringAsFixed(1)}%',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.spaceM),
          Divider(color: AppColors.neutral.withValues(alpha: 0.2)),
          const SizedBox(height: DesignTokens.spaceS),

          // Por bodega
          if (bodegas.porBodega.isEmpty)
            const Padding(
              padding: EdgeInsets.all(DesignTokens.spaceM),
              child: Center(
                child: Text(
                  'No hay distribuciones de bodega configuradas',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ...bodegas.porBodega.map((b) => _BodegaRow(
                  bodega: b,
                  numberFormat: numberFormat,
                  intFormat: intFormat,
                )),
        ],
      ),
    );
  }

  Widget _buildJornadasButton(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push('/graneles/servicio/${dashboard.servicio.id}/jornadas');
      },
      borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.spaceM),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondary,
              AppColors.secondary.withValues(alpha: 0.85),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: const Icon(
                Icons.table_chart_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: DesignTokens.spaceM),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen por Jornadas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Descarga y despacho por bodega/almacen',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: DesignTokens.spaceS),
        Text(
          title,
          style: const TextStyle(
            fontSize: DesignTokens.fontSizeM,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// COMPONENTES AUXILIARES
// =============================================================================

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeaderChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: DesignTokens.spaceXS),
        Text(
          text,
          style: const TextStyle(
            fontSize: DesignTokens.fontSizeXS,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final double? percentage;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.unit,
    this.percentage,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.spaceXS),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
              if (percentage != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spaceS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Text(
                    '${percentage!.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeXS,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceS),
          Text(
            title,
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeXS,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: DesignTokens.spaceXS),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: DesignTokens.spaceXS),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeXS,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spaceS),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}

class _ViajeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ViajeItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(DesignTokens.spaceS),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: DesignTokens.spaceS),
        Text(
          value,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeL,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: DesignTokens.fontSizeXS,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SilosSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SilosSummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: DesignTokens.fontSizeXS,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceXS),
        Text(
          value,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SilosProductoRow extends StatelessWidget {
  final SilosProducto producto;
  final NumberFormat numberFormat;
  final NumberFormat intFormat;

  const _SilosProductoRow({
    required this.producto,
    required this.numberFormat,
    required this.intFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceS),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.neutral.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.grain, size: 14, color: AppColors.secondary),
          const SizedBox(width: DesignTokens.spaceS),
          Expanded(
            flex: 2,
            child: Text(
              producto.producto,
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeS,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: DesignTokens.spaceS),
          Text(
            '${numberFormat.format(producto.peso)} TM',
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeXS,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: DesignTokens.spaceM),
          Text(
            '${intFormat.format(producto.viajes)}v',
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeXS,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductoExpandableCard extends StatefulWidget {
  final DashboardProducto producto;

  const _ProductoExpandableCard({required this.producto});

  @override
  State<_ProductoExpandableCard> createState() => _ProductoExpandableCardState();
}

class _ProductoExpandableCardState extends State<_ProductoExpandableCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0.00', 'es');
    final producto = widget.producto;

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header del producto
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceM),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(DesignTokens.spaceS),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                        ),
                        child: const Icon(Icons.grain, size: 20, color: Colors.white),
                      ),
                      const SizedBox(width: DesignTokens.spaceM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              producto.producto,
                              style: const TextStyle(
                                fontSize: DesignTokens.fontSizeM,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: DesignTokens.spaceXS),
                            Text(
                              '${numberFormat.format(producto.pesoManifestado)} TM manifestado',
                              style: const TextStyle(
                                fontSize: DesignTokens.fontSizeXS,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceM),

                  // Mini progress bars
                  Row(
                    children: [
                      Expanded(
                        child: _MiniProgress(
                          label: 'Descarga',
                          percentage: producto.porcentajeDescarga,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spaceM),
                      Expanded(
                        child: _MiniProgress(
                          label: 'Despacho',
                          percentage: producto.porcentajeDespacho,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Contenido expandido
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(producto, numberFormat),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(
    DashboardProducto producto,
    NumberFormat numberFormat,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(DesignTokens.radiusL),
          bottomRight: Radius.circular(DesignTokens.radiusL),
        ),
      ),
      child: Column(
        children: [
          // Datos detallados
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceM),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DetailItem(
                        label: 'Descargado',
                        value: '${numberFormat.format(producto.pesoDescargado)} TM',
                        color: AppColors.success,
                      ),
                    ),
                    Expanded(
                      child: _DetailItem(
                        label: 'Despachado',
                        value: '${numberFormat.format(producto.pesoDespachado)} TM',
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spaceM),
                Row(
                  children: [
                    Expanded(
                      child: _DetailItem(
                        label: 'Viajes Muelle',
                        value: '${producto.viajesMuelle}',
                        color: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: _DetailItem(
                        label: 'Viajes Balanza',
                        value: '${producto.viajesBalanza}',
                        color: AppColors.secondary,
                      ),
                    ),
                    Expanded(
                      child: _DetailItem(
                        label: 'Viajes Almacén',
                        value: '${producto.viajesAlmacen}',
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bodegas de la nave (descarga)
          if (producto.bodegas.isNotEmpty) ...[
            Divider(height: 1, color: AppColors.neutral.withValues(alpha: 0.2)),
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.directions_boat, size: 16, color: AppColors.primary),
                      SizedBox(width: DesignTokens.spaceXS),
                      Text(
                        'Descarga por Bodega',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeS,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceS),
                  ...producto.bodegas.map(
                    (bodega) => _BodegaRowCompact(
                      bodega: bodega,
                      numberFormat: numberFormat,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Distribuciones (almacenes destino)
          if (producto.distribuciones.isNotEmpty) ...[
            Divider(height: 1, color: AppColors.neutral.withValues(alpha: 0.2)),
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warehouse, size: 16, color: AppColors.accent),
                      SizedBox(width: DesignTokens.spaceXS),
                      Text(
                        'Despacho a Almacén',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeS,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceS),
                  ...producto.distribuciones.map(
                    (dist) => _DistribucionRow(
                      distribucion: dist,
                      numberFormat: numberFormat,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniProgress extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;

  const _MiniProgress({
    required this.label,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeXS,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeXS,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spaceXS),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DetailItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: DesignTokens.fontSizeXS,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.spaceXS),
        Text(
          value,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _DistribucionRow extends StatelessWidget {
  final DistribucionAlmacenDashboard distribucion;
  final NumberFormat numberFormat;

  const _DistribucionRow({
    required this.distribucion,
    required this.numberFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceS),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.neutral.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: DesignTokens.spaceS),
          Expanded(
            flex: 2,
            child: Text(
              distribucion.almacen,
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeS,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${numberFormat.format(distribucion.pesoBalanza)} TM',
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeXS,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
              Text(
                '${distribucion.viajesBalanza} viajes',
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeXS,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BodegaSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BodegaSummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: DesignTokens.fontSizeXS,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceXS),
        Text(
          value,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BodegaRowCompact extends StatelessWidget {
  final BodegaItem bodega;
  final NumberFormat numberFormat;

  const _BodegaRowCompact({
    required this.bodega,
    required this.numberFormat,
  });

  @override
  Widget build(BuildContext context) {
    final porcentaje = bodega.porcentajeDescarga;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceS),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.neutral.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // Nombre bodega
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceS,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Text(
              bodega.bodega,
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeXS,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.spaceS),
          // Barra de progreso
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (porcentaje / 100).clamp(0.0, 1.0),
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(
                  porcentaje >= 100 ? AppColors.success : AppColors.primary,
                ),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.spaceS),
          // Porcentaje y valores
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${porcentaje.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXS,
                  fontWeight: FontWeight.bold,
                  color: porcentaje >= 100 ? AppColors.success : AppColors.primary,
                ),
              ),
              Text(
                '${numberFormat.format(bodega.descargado)}/${numberFormat.format(bodega.manifestado)}',
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeXS,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BodegaRow extends StatelessWidget {
  final BodegaItem bodega;
  final NumberFormat numberFormat;
  final NumberFormat intFormat;

  const _BodegaRow({
    required this.bodega,
    required this.numberFormat,
    required this.intFormat,
  });

  @override
  Widget build(BuildContext context) {
    final porcentaje = bodega.porcentajeDescarga;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceS),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.neutral.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre de bodega y porcentaje
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceS,
                  vertical: DesignTokens.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Text(
                  bodega.bodega,
                  style: const TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${porcentaje.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: FontWeight.bold,
                  color: porcentaje >= 100 ? AppColors.success : AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceS),

          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (porcentaje / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                porcentaje >= 100 ? AppColors.success : AppColors.primary,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: DesignTokens.spaceS),

          // Detalles: Manifestado / Descargado / Viajes
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: DesignTokens.fontSizeXS),
                    children: [
                      const TextSpan(
                        text: 'Manif: ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextSpan(
                        text: numberFormat.format(bodega.manifestado),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: DesignTokens.fontSizeXS),
                    children: [
                      const TextSpan(
                        text: 'Desc: ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextSpan(
                        text: numberFormat.format(bodega.descargado),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: DesignTokens.fontSizeXS),
                  children: [
                    const TextSpan(
                      text: 'Viajes: ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextSpan(
                      text: '${bodega.viajes}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
