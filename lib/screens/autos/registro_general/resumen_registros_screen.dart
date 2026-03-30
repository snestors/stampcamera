import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/services/http_service.dart';

// =============================================================================
// MODELS
// =============================================================================

class ResumenHora {
  final int hora;
  final String label;
  final int total;
  final List<ResumenUsuario> participantes;

  ResumenHora({
    required this.hora,
    required this.label,
    required this.total,
    required this.participantes,
  });

  factory ResumenHora.fromJson(Map<String, dynamic> json) {
    return ResumenHora(
      hora: json['hora'] as int,
      label: json['label'] as String,
      total: json['total'] as int,
      participantes: (json['participantes'] as List)
          .map((p) => ResumenUsuario.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ResumenDia {
  final String fecha;
  final int total;
  final List<ResumenHora> horas;

  ResumenDia({
    required this.fecha,
    required this.total,
    required this.horas,
  });

  factory ResumenDia.fromJson(Map<String, dynamic> json) {
    return ResumenDia(
      fecha: json['fecha'] as String,
      total: json['total'] as int,
      horas: (json['horas'] as List)
          .map((h) => ResumenHora.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }

  String get fechaFormateada {
    final parts = fecha.split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    return fecha;
  }
}

class ResumenUsuario {
  final int usuarioId;
  final String nombre;
  final int total;

  ResumenUsuario({
    required this.usuarioId,
    required this.nombre,
    required this.total,
  });

  factory ResumenUsuario.fromJson(Map<String, dynamic> json) {
    return ResumenUsuario(
      usuarioId: json['usuario_id'] as int,
      nombre: json['nombre'] as String,
      total: json['total'] as int,
    );
  }
}

class RegistroVinDetalle {
  final int id;
  final String vin;
  final String condicion;
  final String? zonaInspeccion;
  final String? bloque;
  final String hora;
  final String? marca;
  final String? modelo;

  RegistroVinDetalle({
    required this.id,
    required this.vin,
    required this.condicion,
    this.zonaInspeccion,
    this.bloque,
    required this.hora,
    this.marca,
    this.modelo,
  });

  factory RegistroVinDetalle.fromJson(Map<String, dynamic> json) {
    return RegistroVinDetalle(
      id: json['id'] as int,
      vin: json['vin'] as String,
      condicion: json['condicion'] as String,
      zonaInspeccion: json['zona_inspeccion'] as String?,
      bloque: json['bloque'] as String?,
      hora: json['hora'] as String,
      marca: json['marca'] as String?,
      modelo: json['modelo'] as String?,
    );
  }
}

// =============================================================================
// PROVIDER
// =============================================================================

final resumenRegistrosProvider = StateNotifierProvider.autoDispose<
    ResumenRegistrosNotifier, AsyncValue<List<ResumenDia>>>((ref) {
  return ResumenRegistrosNotifier();
});

class ResumenRegistrosNotifier extends StateNotifier<AsyncValue<List<ResumenDia>>> {
  ResumenRegistrosNotifier() : super(const AsyncValue.loading());

  String _modo = 'todos';
  String get modo => _modo;

  Future<void> cargar({String modo = 'todos'}) async {
    _modo = modo;
    state = const AsyncValue.loading();
    try {
      final response = await HttpService().dio.get(
        'api/v1/autos/registro-vin/resumen-registros/',
        queryParameters: {'modo': modo},
      );
      final results = (response.data['results'] as List)
          .map((e) => ResumenDia.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<RegistroVinDetalle>> cargarDetalleUsuario({
    required String fecha,
    required int usuarioId,
    required int hora,
  }) async {
    final response = await HttpService().dio.get(
      'api/v1/autos/registro-vin/resumen-registros/',
      queryParameters: {
        'modo': _modo,
        'fecha': fecha,
        'usuario_id': usuarioId.toString(),
        'hora': hora.toString(),
      },
    );
    return (response.data['results'] as List)
        .map((e) => RegistroVinDetalle.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// =============================================================================
// SCREEN
// =============================================================================

class ResumenRegistrosScreen extends ConsumerStatefulWidget {
  const ResumenRegistrosScreen({super.key});

  @override
  ConsumerState<ResumenRegistrosScreen> createState() => _ResumenRegistrosScreenState();
}

class _ResumenRegistrosScreenState extends ConsumerState<ResumenRegistrosScreen> {
  bool _soloMios = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(resumenRegistrosProvider.notifier).cargar());
  }

  void _toggleModo() {
    setState(() => _soloMios = !_soloMios);
    ref.read(resumenRegistrosProvider.notifier).cargar(
      modo: _soloMios ? 'mis' : 'todos',
    );
  }

  @override
  Widget build(BuildContext context) {
    final resumenAsync = ref.watch(resumenRegistrosProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Registros VIN',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: DesignTokens.fontSizeL,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: DesignTokens.spaceM),
            child: FilterChip(
              label: Text(
                _soloMios ? 'Mis registros' : 'Todos',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXS,
                  color: _soloMios ? Colors.white : AppColors.primary,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
              selected: _soloMios,
              onSelected: (_) => _toggleModo(),
              selectedColor: AppColors.secondary,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
      body: resumenAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => AppErrorState(
          message: 'Error al cargar registros',
          onRetry: () => ref.read(resumenRegistrosProvider.notifier).cargar(
            modo: _soloMios ? 'mis' : 'todos',
          ),
        ),
        data: (dias) {
          if (dias.isEmpty) {
            return AppEmptyState(
              icon: Icons.assignment_outlined,
              title: _soloMios ? 'No tienes registros' : 'No hay registros',
              subtitle: _soloMios
                  ? 'Aún no has realizado registros VIN'
                  : 'No se encontraron registros en el sistema',
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(resumenRegistrosProvider.notifier).cargar(
              modo: _soloMios ? 'mis' : 'todos',
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(DesignTokens.spacingPage),
              itemCount: dias.length,
              itemBuilder: (context, index) => _DiaCard(dia: dias[index]),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// DIA CARD
// =============================================================================

class _DiaCard extends StatefulWidget {
  final ResumenDia dia;
  const _DiaCard({required this.dia});

  @override
  State<_DiaCard> createState() => _DiaCardState();
}

class _DiaCardState extends State<_DiaCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceM),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header del día
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingCard),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.spaceS),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                    ),
                    child: const Icon(Icons.calendar_today,
                        color: AppColors.primary, size: DesignTokens.iconXL),
                  ),
                  const SizedBox(width: DesignTokens.spaceL),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.dia.fechaFormateada,
                          style: const TextStyle(
                            fontSize: DesignTokens.fontSizeRegular,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spaceXXS),
                        Text(
                          '${widget.dia.horas.length} franja${widget.dia.horas.length != 1 ? 's' : ''} horaria${widget.dia.horas.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: DesignTokens.fontSizeXS,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceM,
                      vertical: DesignTokens.spaceXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
                    ),
                    child: Text(
                      '${widget.dia.total}',
                      style: const TextStyle(
                        fontSize: DesignTokens.fontSizeRegular,
                        fontWeight: DesignTokens.fontWeightBold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceXS),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: DesignTokens.animationFast,
                    child: const Icon(Icons.expand_more, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // Lista de horas
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1, color: AppColors.divider),
                ...widget.dia.horas.map((h) => _HoraTile(
                  hora: h,
                  fecha: widget.dia.fecha,
                )),
                const SizedBox(height: DesignTokens.spaceS),
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: DesignTokens.animationNormal,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HORA TILE
// =============================================================================

class _HoraTile extends StatefulWidget {
  final ResumenHora hora;
  final String fecha;
  const _HoraTile({required this.hora, required this.fecha});

  @override
  State<_HoraTile> createState() => _HoraTileState();
}

class _HoraTileState extends State<_HoraTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingCard,
              vertical: DesignTokens.spaceM,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spaceS),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: const Icon(Icons.access_time,
                      color: AppColors.info, size: DesignTokens.iconL),
                ),
                const SizedBox(width: DesignTokens.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.hora.label,
                        style: const TextStyle(
                          fontSize: DesignTokens.fontSizeS,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${widget.hora.participantes.length} participante${widget.hora.participantes.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          color: AppColors.textSecondary,
                        ),
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
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
                  ),
                  child: Text(
                    '${widget.hora.total}',
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeXS,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: AppColors.info,
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceXS),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: DesignTokens.animationFast,
                  child: const Icon(Icons.expand_more,
                      size: DesignTokens.iconXL, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),

        if (_expanded) ...[
          ...widget.hora.participantes.map((p) => _ParticipanteTile(
            participante: p,
            fecha: widget.fecha,
            hora: widget.hora.hora,
          )),
        ],
      ],
    );
  }
}

// =============================================================================
// PARTICIPANTE TILE
// =============================================================================

class _ParticipanteTile extends ConsumerStatefulWidget {
  final ResumenUsuario participante;
  final String fecha;
  final int hora;
  const _ParticipanteTile({
    required this.participante,
    required this.fecha,
    required this.hora,
  });

  @override
  ConsumerState<_ParticipanteTile> createState() => _ParticipanteTileState();
}

class _ParticipanteTileState extends ConsumerState<_ParticipanteTile> {
  bool _expanded = false;
  List<RegistroVinDetalle>? _vins;
  bool _loading = false;

  Future<void> _toggle() async {
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }

    if (_vins == null) {
      setState(() => _loading = true);
      try {
        final notifier = ref.read(resumenRegistrosProvider.notifier);
        final result = await notifier.cargarDetalleUsuario(
          fecha: widget.fecha,
          usuarioId: widget.participante.usuarioId,
          hora: widget.hora,
        );
        setState(() {
          _vins = result;
          _expanded = true;
          _loading = false;
        });
      } catch (e) {
        setState(() => _loading = false);
        if (mounted) {
          AppSnackBar.error(context, 'Error al cargar VINs');
        }
      }
    } else {
      setState(() => _expanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.only(
              left: DesignTokens.spacingCard + DesignTokens.spaceXXL,
              right: DesignTokens.spacingCard,
              top: DesignTokens.spaceS,
              bottom: DesignTokens.spaceS,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    widget.participante.nombre.isNotEmpty
                        ? widget.participante.nombre[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: DesignTokens.fontWeightBold,
                      fontSize: DesignTokens.fontSizeXS,
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceM),
                Expanded(
                  child: Text(
                    widget.participante.nombre,
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spaceS,
                    vertical: DesignTokens.spaceXXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
                  ),
                  child: Text(
                    '${widget.participante.total}',
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeXS,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceXS),
                if (_loading)
                  const SizedBox(
                    width: DesignTokens.iconL,
                    height: DesignTokens.iconL,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                else
                  Icon(
                    _expanded ? Icons.expand_less : Icons.chevron_right,
                    size: DesignTokens.iconXL,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),

        // Lista de VINs
        if (_expanded && _vins != null) ...[
          ..._vins!.map((vin) => _VinTile(detalle: vin)),
          const SizedBox(height: DesignTokens.spaceS),
        ],
      ],
    );
  }
}

// =============================================================================
// VIN TILE
// =============================================================================

class _VinTile extends StatelessWidget {
  final RegistroVinDetalle detalle;
  const _VinTile({required this.detalle});

  Color _condicionColor(String condicion) {
    switch (condicion) {
      case 'PUERTO': return AppColors.puerto;
      case 'RECEPCION': return AppColors.recepcion;
      case 'ALMACEN': return AppColors.almacen;
      case 'PDI': return AppColors.pdi;
      case 'PRE-PDI': return AppColors.prePdi;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _condicionColor(detalle.condicion);
    final descripcion = [
      if (detalle.marca != null) detalle.marca,
      if (detalle.modelo != null) detalle.modelo,
    ].join(' ');

    return InkWell(
      onTap: () => context.push('/autos/detalle/${detalle.vin}'),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingCard + DesignTokens.spaceXXL,
          vertical: DesignTokens.spaceXXS,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceM,
          vertical: DesignTokens.spaceS,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
              ),
            ),
            const SizedBox(width: DesignTokens.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detalle.vin,
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontFamily: 'monospace',
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (descripcion.isNotEmpty)
                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: DesignTokens.fontSizeXS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceS,
                vertical: DesignTokens.spaceXXS,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
              ),
              child: Text(
                detalle.condicion,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXXS,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.spaceS),
            Text(
              detalle.hora,
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeXS,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: DesignTokens.spaceXS),
            const Icon(Icons.chevron_right,
                size: DesignTokens.iconM, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
