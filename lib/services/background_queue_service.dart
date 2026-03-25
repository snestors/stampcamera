// lib/services/background_queue_service.dart - OPTIMIZADO (reemplaza el actual)
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/providers/autos/queue_state_provider.dart';
import 'package:stampcamera/services/registro_vin_service.dart';

class BackgroundQueueService {
  static final BackgroundQueueService _instance =
      BackgroundQueueService._internal();
  factory BackgroundQueueService() => _instance;
  BackgroundQueueService._internal();

  Timer? _timer;
  bool _isProcessing = false;
  int _failureCount = 0;
  ProviderContainer? _container;

  final RegistroVinService _registroService = RegistroVinService();

  /// Inicializar con acceso a providers
  void initialize(ProviderContainer container) {
    _container = container;
  }

  /// Iniciar el servicio background
  void start() {
    if (_timer?.isActive == true) return;

    debugPrint('🚀 BackgroundQueueService iniciado');
    // ✅ OPTIMIZACIÓN: Empezar con 30s en lugar de 15s
    _scheduleNextRun(const Duration(seconds: 30));
  }

  /// Parar el servicio
  void stop() {
    _timer?.cancel();
    _timer = null;
    debugPrint('🛑 BackgroundQueueService detenido');
  }

  /// Programar la próxima ejecución
  void _scheduleNextRun(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _processQueue);
  }

  /// ✅ OPTIMIZACIÓN: Usar el provider unificado en lugar de múltiples llamadas
  Future<void> _processQueue() async {
    if (_isProcessing) {
      debugPrint('⏳ Ya hay procesamiento en curso, saltando...');
      // ✅ OPTIMIZACIÓN: Delay más inteligente
      _scheduleNextRun(const Duration(seconds: 15));
      return;
    }

    _isProcessing = true;
    debugPrint('🔄 Iniciando procesamiento de cola...');

    try {
      // ✅ VERIFICAR CONECTIVIDAD ANTES
      if (!await _hasInternetConnection()) {
        debugPrint('📡 Sin conexión a internet, saltando procesamiento');
        _scheduleNextRun(const Duration(seconds: 30));
        return;
      }

      // ✅ OPTIMIZACIÓN: Usar el provider unificado
      int pendingCount = 0;
      if (_container != null) {
        try {
          final queueState = _container!.read(queueStateProvider);
          pendingCount = queueState.pendingCount;
        } catch (e) {
          // Fallback si el provider no está disponible
          pendingCount = await _registroService.getPendingCount();
        }
      } else {
        pendingCount = await _registroService.getPendingCount();
      }

      if (pendingCount == 0) {
        debugPrint('✅ No hay registros pendientes');
        _failureCount = 0;
        // ✅ OPTIMIZACIÓN: Interval más espaciado cuando no hay trabajo
        _scheduleNextRun(const Duration(seconds: 60));
        return;
      }

      debugPrint('📋 Procesando $pendingCount registro(s) pendiente(s)...');

      // ✅ Procesar la cola
      await _registroService.processPendingQueue();

      // ✅ OPTIMIZACIÓN: Refrescar solo el provider unificado
      if (_container != null) {
        _container!.read(queueStateProvider.notifier).refreshState();
      }

      debugPrint('✅ Cola procesada exitosamente');
      _failureCount = 0;

      // ✅ OPTIMIZACIÓN: Interval más frecuente cuando hay trabajo exitoso
      _scheduleNextRun(const Duration(seconds: 30));
    } catch (e) {
      debugPrint('❌ Error procesando cola: $e');
      _failureCount++;

      // ✅ OPTIMIZACIÓN: Backoff más agresivo para evitar spam
      final backoffDelay = _calculateBackoffDelay();
      debugPrint(
        '⏰ Reintentando en ${backoffDelay.inSeconds} segundos (fallo #$_failureCount)',
      );
      _scheduleNextRun(backoffDelay);
    } finally {
      _isProcessing = false;
    }
  }

  /// Verificar conectividad
  Future<bool> _hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint('Error verificando conectividad: $e');
      return false;
    }
  }

  /// ✅ OPTIMIZACIÓN: Backoff más inteligente
  Duration _calculateBackoffDelay() {
    switch (_failureCount) {
      case 1:
        return const Duration(seconds: 15); // Primer fallo: 15s
      case 2:
        return const Duration(seconds: 45); // Segundo fallo: 45s
      case 3:
        return const Duration(minutes: 2); // Tercer fallo: 2min
      default:
        return const Duration(minutes: 5); // Fallos múltiples: 5min (máximo)
    }
  }

  /// Forzar procesamiento inmediato
  Future<void> forceProcess() async {
    if (_isProcessing) {
      debugPrint('⏳ Ya hay procesamiento en curso');
      return;
    }

    debugPrint('🔄 Procesamiento forzado solicitado');
    await _processQueue();
  }

  /// Obtener estado del servicio
  Map<String, dynamic> getStatus() {
    return {
      'isRunning': _timer?.isActive ?? false,
      'isProcessing': _isProcessing,
      'failureCount': _failureCount,
      'nextRunIn': _timer?.isActive == true ? 'Programado' : 'Detenido',
    };
  }
}

// ============================================================================
// ✅ OPTIMIZACIÓN: SINGLETON GLOBAL PARA FÁCIL ACCESO
// ============================================================================
final backgroundQueueService = BackgroundQueueService();
