import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/asistencia/asistencia_model.dart';
import 'package:stampcamera/providers/asistencia/asistencias_provider.dart';
import 'package:stampcamera/widgets/asistencia/marcar_salida.dart';
import 'package:stampcamera/widgets/asistencia/modal_entrada.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

class RegistroAsistenciaScreen extends ConsumerStatefulWidget {
  const RegistroAsistenciaScreen({super.key});

  @override
  ConsumerState<RegistroAsistenciaScreen> createState() =>
      _RegistroAsistenciaScreenState();
}

class _RegistroAsistenciaScreenState
    extends ConsumerState<RegistroAsistenciaScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _timer;
  final ValueNotifier<Duration> _elapsedTime = ValueNotifier(Duration.zero);
  DateTime? _entryTime;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    _elapsedTime.dispose();
    super.dispose();
  }

  void _startTimer(DateTime entryTime) {
    _entryTime = entryTime;
    _updateElapsedTime();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateElapsedTime();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _updateElapsedTime() {
    if (_entryTime != null) {
      _elapsedTime.value = DateTime.now().difference(_entryTime!);
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    ref.invalidate(asistenciaActivaProvider);
    await ref.read(asistenciaActivaProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final asistenciaAsync = ref.watch(asistenciaActivaProvider);
    final formOptionsAsync = ref.watch(asistenciaFormOptionsProvider);
    final status = ref.watch(asistenciaStatusProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Registro de Asistencia'),
        backgroundColor: const Color(0xFF003B5C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _handleRefresh(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: asistenciaAsync.when(
        data: (response) {
          if (!response.tieneAsistenciaActiva || response.asistencia == null) {
            _stopTimer();
            return _buildEmptyState(context);
          }

          final asistencia = response.asistencia!;

          // Iniciar timer si no está corriendo
          if (_timer == null || !_timer!.isActive) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startTimer(asistencia.fechaHoraEntrada);
            });
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: const Color(0xFF003B5C),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              child: _buildActiveCard(asistencia),
            ),
          );
        },
        loading: () => _buildLoadingState(),
        error: (e, _) => ConnectionErrorScreen(
          onRetry: () => ref.invalidate(asistenciaActivaProvider),
        ),
      ),
      floatingActionButton: _buildFAB(asistenciaAsync, formOptionsAsync, status),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildActiveCard(Asistencia asistencia) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003B5C), Color(0xFF00587A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003B5C).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Timer section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) => Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(
                            alpha: 0.5 + (_pulseController.value * 0.5),
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withValues(
                                alpha: _pulseController.value * 0.5,
                              ),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'JORNADA ACTIVA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<Duration>(
                  valueListenable: _elapsedTime,
                  builder: (context, elapsed, _) => Text(
                    _formatDuration(elapsed),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      fontFamily: 'monospace',
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tiempo trabajado',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              color: Colors.white.withValues(alpha: 0.2),
              height: 1,
            ),
          ),

          // Details section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                _buildDetailRow(
                  Icons.login_rounded,
                  'Entrada',
                  _formatTime(asistencia.fechaHoraEntrada),
                ),
                if (asistencia.zonaTrabajo != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.place_rounded,
                    'Zona',
                    asistencia.zonaTrabajo!.value,
                  ),
                ],
                if (asistencia.nave != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.directions_boat_rounded,
                    'Nave',
                    asistencia.nave!.value,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.7)),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono animado
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) => Transform.scale(
                      scale: value,
                      child: child,
                    ),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF003B5C).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        size: 60,
                        color: Color(0xFF003B5C),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Sin asistencia activa',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003B5C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Marca tu entrada para comenzar\ntu jornada laboral',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Indicador visual
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_downward_rounded,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Presiona el botón abajo',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_downward_rounded,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF003B5C),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Cargando asistencia...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFAB(
    AsyncValue asistenciaAsync,
    AsyncValue formOptionsAsync,
    AsistenciaStatus status,
  ) {
    return asistenciaAsync.when(
      data: (response) {
        if (response.tieneAsistenciaActiva) {
          return const BotonMarcarSalida();
        }

        // Botón de entrada
        final isLoading = status == AsistenciaStatus.entradaLoading;

        return formOptionsAsync.when(
          data: (_) => FloatingActionButton.extended(
            heroTag: 'btn_entrada',
            onPressed: isLoading
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    showMarcarEntradaBottomSheet(context, ref);
                  },
            backgroundColor:
                isLoading ? Colors.grey[400] : const Color(0xFF00B4D8),
            elevation: isLoading ? 0 : 4,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.login_rounded),
            label: Text(
              isLoading ? 'Cargando...' : 'Marcar Entrada',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          loading: () => FloatingActionButton.extended(
            heroTag: 'btn_entrada_loading',
            onPressed: null,
            backgroundColor: Colors.grey[300],
            icon: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            label: const Text('Cargando...'),
          ),
          error: (e, st) => FloatingActionButton.extended(
            heroTag: 'btn_entrada_error',
            onPressed: () => ref.invalidate(asistenciaFormOptionsProvider),
            backgroundColor: Colors.orange[400],
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        );
      },
      loading: () => null,
      error: (e, st) => null,
    );
  }
}
