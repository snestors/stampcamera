import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/models/autos/reporte_pedeteo_model.dart';
import 'package:stampcamera/services/autos/reporte_pedeteo_service.dart';

/// Provider del servicio de reporte
final _reporteServiceProvider = Provider((ref) => ReportePedeteoService());

/// Provider para el reporte con fecha
final reportePedeteoProvider = FutureProvider.family<ReportePedeteoJornadas, String?>(
  (ref, fecha) async {
    final service = ref.read(_reporteServiceProvider);
    return service.getReportePorJornadas(fecha: fecha);
  },
);

class ReportePedeteoScreen extends ConsumerStatefulWidget {
  const ReportePedeteoScreen({super.key});

  @override
  ConsumerState<ReportePedeteoScreen> createState() => _ReportePedeteoScreenState();
}

class _ReportePedeteoScreenState extends ConsumerState<ReportePedeteoScreen> {
  DateTime _selectedDate = DateTime.now();
  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    final fechaStr = _dateFormat.format(_selectedDate);
    final reporteAsync = ref.watch(reportePedeteoProvider(fechaStr));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Pedeteo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: 'Seleccionar fecha',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(reportePedeteoProvider(fechaStr)),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con fecha
          _buildDateHeader(),

          // Contenido
          Expanded(
            child: reporteAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    SizedBox(height: DesignTokens.spaceM),
                    Text(
                      'Error al cargar reporte',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeM,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spaceS),
                    TextButton.icon(
                      onPressed: () => ref.invalidate(reportePedeteoProvider(fechaStr)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (reporte) => _buildReporteContent(reporte),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: AppColors.neutral),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, color: AppColors.primary),
          SizedBox(width: DesignTokens.spaceS),
          Text(
            DateFormat('dd/MM/yyyy').format(_selectedDate),
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _selectDate,
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  Widget _buildReporteContent(ReportePedeteoJornadas reporte) {
    if (reporte.totalGeneral == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppColors.textSecondary),
            SizedBox(height: DesignTokens.spaceM),
            Text(
              'Sin registros para esta fecha',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen total
          _buildTotalCard(reporte.totalGeneral),
          SizedBox(height: DesignTokens.spaceL),

          // Jornadas
          ...reporte.jornadas.map((jornada) => _buildJornadaCard(jornada)),
        ],
      ),
    );
  }

  Widget _buildTotalCard(int total) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Pedeteados',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: DesignTokens.spaceXS),
          Text(
            total.toString(),
            style: TextStyle(
              fontSize: DesignTokens.fontSizeXXL,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'unidades',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJornadaCard(JornadaReporte jornada) {
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: AppColors.neutral),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: jornada.total > 0,
          leading: Container(
            padding: EdgeInsets.all(DesignTokens.spaceS),
            decoration: BoxDecoration(
              color: _getJornadaColor(jornada.nombre).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Icon(
              _getJornadaIcon(jornada.nombre),
              color: _getJornadaColor(jornada.nombre),
            ),
          ),
          title: Text(
            jornada.nombre,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: DesignTokens.fontSizeM,
            ),
          ),
          subtitle: Text(
            '${jornada.total} unidades',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceM,
              vertical: DesignTokens.spaceXS,
            ),
            decoration: BoxDecoration(
              color: _getJornadaColor(jornada.nombre),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Text(
              jornada.total.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          children: [
            if (jornada.personas.isEmpty)
              Padding(
                padding: EdgeInsets.all(DesignTokens.spaceM),
                child: Text(
                  'Sin registros en esta jornada',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...jornada.personas.map((persona) => _buildPersonaItem(persona)),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonaItem(PersonaPedeteo persona) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.neutral.withValues(alpha: 0.5)),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceM,
            vertical: 0,
          ),
          childrenPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
            child: Text(
              _getInitials(persona.nombre),
              style: TextStyle(
                fontSize: DesignTokens.fontSizeXS,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
          title: Text(
            persona.nombre,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            '${persona.resumenPorHora.length} horas activas',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeXS,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceS,
              vertical: DesignTokens.spaceXS,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Text(
              persona.cantidad.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
                fontSize: DesignTokens.fontSizeS,
              ),
            ),
          ),
          children: [
            _buildResumenPorHora(persona.resumenPorHora, persona.cantidad),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenPorHora(List<ResumenHora> resumen, int total) {
    if (resumen.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(DesignTokens.spaceM),
        child: Text(
          'Sin desglose disponible',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Encontrar el máximo para calcular porcentajes
    final maxCantidad = resumen.map((r) => r.cantidad).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.spaceM,
        0,
        DesignTokens.spaceM,
        DesignTokens.spaceM,
      ),
      child: Column(
        children: resumen.map((r) {
          final porcentaje = total > 0 ? (r.cantidad / total * 100) : 0.0;
          final barWidth = maxCantidad > 0 ? (r.cantidad / maxCantidad) : 0.0;

          return Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.spaceXS),
            child: Row(
              children: [
                // Hora
                SizedBox(
                  width: 50,
                  child: Text(
                    r.hora,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeXS,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                // Barra de progreso
                Expanded(
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.neutral.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: barWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: DesignTokens.spaceS),
                // Cantidad y porcentaje
                SizedBox(
                  width: 65,
                  child: Text(
                    '${r.cantidad} (${porcentaje.toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeXS,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getJornadaColor(String nombre) {
    if (nombre.contains('07:00 - 15:00')) return AppColors.warning;
    if (nombre.contains('15:00 - 23:00')) return AppColors.secondary;
    return AppColors.accent; // Nocturna
  }

  IconData _getJornadaIcon(String nombre) {
    if (nombre.contains('07:00 - 15:00')) return Icons.wb_sunny;
    if (nombre.contains('15:00 - 23:00')) return Icons.wb_twilight;
    return Icons.nightlight_round; // Nocturna
  }

  String _getInitials(String nombre) {
    final parts = nombre.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }
}
