// lib/services/unified_queue_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stampcamera/services/registro_vin_service.dart';
import 'package:stampcamera/services/fotos_presentacion_service.dart';
import 'package:stampcamera/services/danos_service.dart';
import 'package:stampcamera/services/contenedores_service.dart';
import 'package:stampcamera/services/inventarios_service.dart';

/// Servicio unificado que gestiona todas las colas offline-first
/// Reemplaza múltiples servicios individuales con una sola fuente de verdad
class UnifiedQueueService {
  static final UnifiedQueueService _instance = UnifiedQueueService._internal();
  factory UnifiedQueueService() => _instance;
  UnifiedQueueService._internal();

  // ============================================================================
  // SERVICIOS INDIVIDUALES
  // ============================================================================
  final RegistroVinService _registroVinService = RegistroVinService();
  final FotosPresentacionService _fotosService = FotosPresentacionService();
  final DanosService _danosService = DanosService();
  final ContenedoresService _contenedoresService = ContenedoresService();
  final InventariosService _inventariosService = InventariosService();

  // ============================================================================
  // ESTADO INTERNO
  // ============================================================================
  final StreamController<UnifiedQueueSnapshot> _stateController =
      StreamController<UnifiedQueueSnapshot>.broadcast();

  Timer? _processingTimer;
  bool _isProcessing = false;
  UnifiedQueueSnapshot _currentSnapshot = UnifiedQueueSnapshot.empty();

  // ============================================================================
  // STREAM PÚBLICO - UNA SOLA FUENTE DE VERDAD
  // ============================================================================
  Stream<UnifiedQueueSnapshot> get stateStream => _stateController.stream;
  UnifiedQueueSnapshot get currentState => _currentSnapshot;

  // ============================================================================
  // INICIALIZACIÓN
  // ============================================================================
  Future<void> initialize() async {
    await _loadSnapshot();
    _startAutoProcessing();
    _listenToConnectivity();
  }

  void dispose() {
    _processingTimer?.cancel();
    _stateController.close();
  }

  // ============================================================================
  // CONTEOS UNIFICADOS
  // ============================================================================

  /// Obtener snapshot completo de todas las colas
  Future<void> _loadSnapshot() async {
    try {
      final registroVinCount = await _registroVinService.getPendingCount();
      final fotosCount = await _fotosService.getPendingCount();
      final danosCount = await _danosService.getPendingCount();
      final contenedoresCount = await _contenedoresService.getPendingCount();
      final inventariosCount = await _inventariosService.getPendingCount();

      _currentSnapshot = UnifiedQueueSnapshot(
        registroVinPending: registroVinCount,
        fotosPending: fotosCount,
        danosPending: danosCount,
        contenedoresPending: contenedoresCount,
        inventariosPending: inventariosCount,
        lastUpdated: DateTime.now(),
      );

      _stateController.add(_currentSnapshot);
    } catch (e) {
      debugPrint('Error loading unified queue snapshot: $e');
    }
  }

  /// Refrescar snapshot manualmente
  Future<void> refreshSnapshot() async {
    await _loadSnapshot();
  }

  // ============================================================================
  // PROCESAMIENTO UNIFICADO
  // ============================================================================

  void _startAutoProcessing() {
    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!_isProcessing && _currentSnapshot.totalPending > 0) {
        processAllQueues();
      }
    });
  }

  void _tryImmediateProcessing() {
    if (!_isProcessing) {
      Future.delayed(const Duration(milliseconds: 1000), processAllQueues);
    }
  }

  /// Procesar todas las colas en secuencia
  Future<void> processAllQueues() async {
    if (_isProcessing) return;

    _isProcessing = true;
    debugPrint('🔄 Iniciando procesamiento unificado de colas...');

    try {
      // Verificar conectividad
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        debugPrint('📡 Sin conexión, saltando procesamiento');
        return;
      }

      // Procesar cada cola en secuencia con manejo de errores individual
      await _processWithErrorHandling(
        'RegistroVin',
        () => _registroVinService.processPendingQueue(),
      );

      await _processWithErrorHandling(
        'Fotos',
        () => _fotosService.processPendingQueue(),
      );

      await _processWithErrorHandling(
        'Daños',
        () => _danosService.processPendingQueue(),
      );

      await _processWithErrorHandling(
        'Contenedores',
        () => _contenedoresService.processPendingQueue(),
      );

      await _processWithErrorHandling(
        'Inventarios',
        () => _inventariosService.processPendingQueue(),
      );

      // Actualizar snapshot después del procesamiento
      await _loadSnapshot();

      debugPrint('✅ Procesamiento unificado completado');
    } catch (e) {
      debugPrint('❌ Error en procesamiento unificado: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Wrapper para procesar con manejo de errores
  Future<void> _processWithErrorHandling(
    String queueName,
    Future<void> Function() processor,
  ) async {
    try {
      await processor();
      debugPrint('✅ Cola $queueName procesada exitosamente');
    } catch (e) {
      debugPrint('❌ Error procesando cola $queueName: $e');
      // No rethrow - continuar con las demás colas
    }
  }

  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none &&
          _currentSnapshot.totalPending > 0) {
        debugPrint('Conectividad restaurada, procesando colas unificadas');
        _tryImmediateProcessing();
      }
    });
  }

  // ============================================================================
  // MÉTODOS DE LIMPIEZA UNIFICADOS
  // ============================================================================

  /// Limpiar todos los registros completados
  Future<void> clearAllCompleted() async {
    try {
      await Future.wait([
        _registroVinService.clearCompleted(),
        _fotosService.clearCompleted(),
        _danosService.clearCompleted(),
        _contenedoresService.clearCompleted(),
        _inventariosService.clearCompleted(),
      ]);

      await _loadSnapshot();
      debugPrint('✅ Todos los registros completados han sido limpiados');
    } catch (e) {
      debugPrint('❌ Error limpiando registros completados: $e');
    }
  }

  /// Obtener registros detallados de todas las colas
  Future<UnifiedQueueDetails> getDetailedQueueStatus() async {
    try {
      final registroVinRecords = await _registroVinService
          .getPendingRecordsList();
      final fotosRecords = await _fotosService.getPendingRecordsList();
      final danosRecords = await _danosService.getPendingRecordsList();
      final contenedoresRecords = await _contenedoresService
          .getPendingRecordsList();
      final inventariosRecords = await _inventariosService
          .getPendingRecordsList();

      return UnifiedQueueDetails(
        registroVinRecords: registroVinRecords,
        fotosRecords: fotosRecords,
        danosRecords: danosRecords,
        contenedoresRecords: contenedoresRecords,
        inventariosRecords: inventariosRecords,
      );
    } catch (e) {
      debugPrint('Error obteniendo detalles de colas: $e');
      return UnifiedQueueDetails.empty();
    }
  }

  /// Reintentar registro específico por tipo y ID
  Future<void> retrySpecificRecord({
    required String recordType,
    required String recordId,
  }) async {
    try {
      switch (recordType) {
        case 'registro_vin':
          await _registroVinService.retrySpecificRecord(recordId);
          break;
        case 'fotos_presentacion':
          await _fotosService.retrySpecificRecord(recordId);
          break;
        case 'danos':
          await _danosService.retrySpecificRecord(recordId);
          break;
        case 'contenedores':
          await _contenedoresService.retrySpecificRecord(recordId);
          break;
        case 'inventarios':
          await _inventariosService.retrySpecificRecord(recordId);
          break;
        default:
          throw Exception('Tipo de registro no válido: $recordType');
      }

      await _loadSnapshot();
      debugPrint('✅ Registro $recordType:$recordId reintentado');
    } catch (e) {
      debugPrint('❌ Error reintentando $recordType:$recordId: $e');
      rethrow;
    }
  }

  /// Eliminar registro específico por tipo y ID
  Future<void> deleteSpecificRecord({
    required String recordType,
    required String recordId,
  }) async {
    try {
      switch (recordType) {
        case 'registro_vin':
          await _registroVinService.deleteSpecificRecord(recordId);
          break;
        case 'fotos_presentacion':
          await _fotosService.deleteSpecificRecord(recordId);
          break;
        case 'danos':
          await _danosService.deleteSpecificRecord(recordId);
          break;
        case 'contenedores':
          await _contenedoresService.deleteSpecificRecord(recordId);
          break;
        case 'inventarios':
          await _inventariosService.deleteSpecificRecord(recordId);
          break;
        default:
          throw Exception('Tipo de registro no válido: $recordType');
      }

      await _loadSnapshot();
      debugPrint('✅ Registro $recordType:$recordId eliminado');
    } catch (e) {
      debugPrint('❌ Error eliminando $recordType:$recordId: $e');
      rethrow;
    }
  }

  // ============================================================================
  // MÉTODOS PARA TRIGGER MANUAL
  // ============================================================================

  /// Forzar procesamiento inmediato
  Future<void> forceProcessing() async {
    await processAllQueues();
  }

  /// Obtener estado del servicio
  Map<String, dynamic> getServiceStatus() {
    return {
      'isRunning': _processingTimer?.isActive ?? false,
      'isProcessing': _isProcessing,
      'totalPending': _currentSnapshot.totalPending,
      'lastUpdated': _currentSnapshot.lastUpdated.toIso8601String(),
      'breakdown': {
        'registroVin': _currentSnapshot.registroVinPending,
        'fotos': _currentSnapshot.fotosPending,
        'danos': _currentSnapshot.danosPending,
        'contenedores': _currentSnapshot.contenedoresPending,
        'inventarios': _currentSnapshot.inventariosPending,
      },
    };
  }
}

// ============================================================================
// MODELOS DE DATOS UNIFICADOS
// ============================================================================

class UnifiedQueueSnapshot {
  final int registroVinPending;
  final int fotosPending;
  final int danosPending;
  final int contenedoresPending;
  final int inventariosPending;
  final DateTime lastUpdated;

  const UnifiedQueueSnapshot({
    required this.registroVinPending,
    required this.fotosPending,
    required this.danosPending,
    required this.contenedoresPending,
    required this.inventariosPending,
    required this.lastUpdated,
  });

  UnifiedQueueSnapshot.empty()
    : registroVinPending = 0,
      fotosPending = 0,
      danosPending = 0,
      contenedoresPending = 0,
      inventariosPending = 0,
      lastUpdated = DateTime(2024, 1, 1);

  int get totalPending =>
      registroVinPending +
      fotosPending +
      danosPending +
      contenedoresPending +
      inventariosPending;

  bool get hasPendingItems => totalPending > 0;

  /// Obtener breakdown como mapa para UI
  Map<String, int> get breakdown => {
    'Registro VIN': registroVinPending,
    'Fotos': fotosPending,
    'Daños': danosPending,
    'Contenedores': contenedoresPending,
    'Inventarios': inventariosPending,
  };
}

class UnifiedQueueDetails {
  final List<Map<String, dynamic>> registroVinRecords;
  final List<Map<String, dynamic>> fotosRecords;
  final List<Map<String, dynamic>> danosRecords;
  final List<Map<String, dynamic>> contenedoresRecords;
  final List<Map<String, dynamic>> inventariosRecords;

  const UnifiedQueueDetails({
    required this.registroVinRecords,
    required this.fotosRecords,
    required this.danosRecords,
    required this.contenedoresRecords,
    required this.inventariosRecords,
  });

  UnifiedQueueDetails.empty()
    : registroVinRecords = const [],
      fotosRecords = const [],
      danosRecords = const [],
      contenedoresRecords = const [],
      inventariosRecords = const [];

  /// Obtener todos los registros agrupados por tipo
  Map<String, List<Map<String, dynamic>>> get allRecords => {
    'registro_vin': registroVinRecords,
    'fotos_presentacion': fotosRecords,
    'danos': danosRecords,
    'contenedores': contenedoresRecords,
    'inventarios': inventariosRecords,
  };

  /// Obtener total de registros
  int get totalRecords =>
      registroVinRecords.length +
      fotosRecords.length +
      danosRecords.length +
      contenedoresRecords.length +
      inventariosRecords.length;
}

// ============================================================================
// SINGLETON GLOBAL
// ============================================================================
final unifiedQueueService = UnifiedQueueService();
