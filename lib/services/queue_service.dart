// lib/services/queue_service.dart - SERVICIO UNIFICADO Y EFICIENTE
import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:stampcamera/services/registro_vin_service.dart';

class QueueService {
  static final QueueService _instance = QueueService._internal();
  factory QueueService() => _instance;
  QueueService._internal();

  // ============================================================================
  // ESTADO INTERNO
  // ============================================================================
  final RegistroVinService _registroService = RegistroVinService();
  final StreamController<QueueSnapshot> _stateController =
      StreamController<QueueSnapshot>.broadcast();

  Timer? _processingTimer;
  bool _isProcessing = false;
  QueueSnapshot _currentSnapshot = QueueSnapshot.empty();

  // ============================================================================
  // STREAM PÚBLICO - UNA SOLA FUENTE DE VERDAD
  // ============================================================================
  Stream<QueueSnapshot> get stateStream => _stateController.stream;
  QueueSnapshot get currentState => _currentSnapshot;

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
  // OPERACIONES PRINCIPALES
  // ============================================================================

  /// Añadir registro a la cola (offline-first)
  Future<bool> addRecord({
    required String vin,
    required String condicion,
    required int zonaInspeccion,
    required String fotoPath,
    int? bloqueId,
    int? fila,
    int? posicion,
    int? contenedorId,
  }) async {
    try {
      final record = QueueRecord(
        id: const Uuid().v4(),
        vin: vin,
        condicion: condicion,
        zonaInspeccion: zonaInspeccion,
        fotoPath: fotoPath,
        bloqueId: bloqueId,
        fila: fila,
        posicion: posicion,
        contenedorId: contenedorId,
        status: QueueStatus.pending,
        createdAt: DateTime.now(),
        retryCount: 0,
      );

      await _addRecordToStorage(record);
      await _updateSnapshot();

      // Intentar envío inmediato si hay conexión
      _tryImmediateProcessing();

      return true;
    } catch (e) {
      debugPrint('Error adding record to queue: $e');
      return false;
    }
  }

  /// Procesar cola manualmente
  Future<void> processQueue() async {
    if (_isProcessing) return;
    await _processAllPending();
  }

  /// Retry de un registro específico
  Future<void> retryRecord(String recordId) async {
    try {
      final records = await _getAllRecords();
      final recordIndex = records.indexWhere((r) => r.id == recordId);

      if (recordIndex == -1) throw Exception('Registro no encontrado');

      final record = records[recordIndex];
      final updatedRecord = record.copyWith(
        status: QueueStatus.pending,
        retryCount: record.retryCount + 1,
        error: null,
      );

      records[recordIndex] = updatedRecord;
      await _saveAllRecords(records);
      await _updateSnapshot();

      // Intentar procesamiento inmediato
      _tryImmediateProcessing();
    } catch (e) {
      debugPrint('Error retrying record: $e');
      rethrow;
    }
  }

  /// Eliminar registro específico
  Future<void> deleteRecord(String recordId) async {
    try {
      final records = await _getAllRecords();
      records.removeWhere((r) => r.id == recordId);
      await _saveAllRecords(records);
      await _updateSnapshot();
    } catch (e) {
      debugPrint('Error deleting record: $e');
    }
  }

  /// Limpiar registros completados
  Future<void> clearCompleted() async {
    try {
      final records = await _getAllRecords();
      final filtered = records
          .where((r) => r.status != QueueStatus.completed)
          .toList();
      await _saveAllRecords(filtered);
      await _updateSnapshot();
    } catch (e) {
      debugPrint('Error clearing completed records: $e');
    }
  }

  /// Limpiar registros fallidos
  Future<void> clearFailed() async {
    try {
      final records = await _getAllRecords();
      final filtered = records
          .where((r) => r.status != QueueStatus.failed)
          .toList();
      await _saveAllRecords(filtered);
      await _updateSnapshot();
    } catch (e) {
      debugPrint('Error clearing failed records: $e');
    }
  }

  // ============================================================================
  // PROCESAMIENTO AUTOMÁTICO
  // ============================================================================

  void _startAutoProcessing() {
    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isProcessing && _currentSnapshot.pendingCount > 0) {
        _processAllPending();
      }
    });
  }

  void _tryImmediateProcessing() {
    if (!_isProcessing) {
      Future.delayed(const Duration(milliseconds: 500), _processAllPending);
    }
  }

  Future<void> _processAllPending() async {
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      // Verificar conectividad
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        debugPrint('Sin conectividad, skipping queue processing');
        return;
      }

      final records = await _getAllRecords();
      final pending = records
          .where((r) => r.status == QueueStatus.pending && r.retryCount < 3)
          .toList();

      if (pending.isEmpty) return;

      debugPrint('Processing ${pending.length} pending records');

      bool hasChanges = false;

      for (int i = 0; i < records.length; i++) {
        final record = records[i];

        if (record.status != QueueStatus.pending || record.retryCount >= 3) {
          continue;
        }

        try {
          await _registroService.createRegistro(
            vin: record.vin,
            condicion: record.condicion,
            zonaInspeccion: record.zonaInspeccion,
            fotoPath: record.fotoPath,
            bloqueId: record.bloqueId,
            fila: record.fila,
            posicion: record.posicion,
            contenedorId: record.contenedorId,
          );

          // Marcar como completado
          records[i] = record.copyWith(
            status: QueueStatus.completed,
            completedAt: DateTime.now(),
            error: null,
          );
          hasChanges = true;

          debugPrint('✅ Record ${record.vin} completed');
        } catch (e) {
          // Incrementar retry count
          final newRetryCount = record.retryCount + 1;
          final newStatus = newRetryCount >= 3
              ? QueueStatus.failed
              : QueueStatus.pending;

          records[i] = record.copyWith(
            retryCount: newRetryCount,
            status: newStatus,
            error: e.toString(),
          );
          hasChanges = true;

          debugPrint('❌ Record ${record.vin} failed (retry: $newRetryCount)');
        }
      }

      if (hasChanges) {
        await _saveAllRecords(records);
        await _updateSnapshot();
      }
    } catch (e) {
      debugPrint('Error processing queue: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none) &&
          _currentSnapshot.pendingCount > 0) {
        debugPrint('Connectivity restored, processing queue');
        _tryImmediateProcessing();
      }
    });
  }

  // ============================================================================
  // STORAGE Y ESTADO
  // ============================================================================

  Future<void> _addRecordToStorage(QueueRecord record) async {
    final records = await _getAllRecords();
    records.add(record);
    await _saveAllRecords(records);
  }

  Future<List<QueueRecord>> _getAllRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('queue_records') ?? '[]';
      final List<dynamic> list = jsonDecode(json);

      return list.map((item) => QueueRecord.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error loading records: $e');
      return [];
    }
  }

  Future<void> _saveAllRecords(List<QueueRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(records.map((r) => r.toJson()).toList());
      await prefs.setString('queue_records', json);
    } catch (e) {
      debugPrint('Error saving records: $e');
    }
  }

  Future<void> _loadSnapshot() async {
    final records = await _getAllRecords();
    _currentSnapshot = QueueSnapshot.fromRecords(records);
  }

  Future<void> _updateSnapshot() async {
    final records = await _getAllRecords();
    _currentSnapshot = QueueSnapshot.fromRecords(records);
    _stateController.add(_currentSnapshot);
  }
}

// ============================================================================
// MODELOS DE DATOS
// ============================================================================

enum QueueStatus { pending, completed, failed }

class QueueRecord {
  final String id;
  final String vin;
  final String condicion;
  final int zonaInspeccion;
  final String fotoPath;
  final int? bloqueId;
  final int? fila;
  final int? posicion;
  final int? contenedorId;
  final QueueStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int retryCount;
  final String? error;

  const QueueRecord({
    required this.id,
    required this.vin,
    required this.condicion,
    required this.zonaInspeccion,
    required this.fotoPath,
    this.bloqueId,
    this.fila,
    this.posicion,
    this.contenedorId,
    required this.status,
    required this.createdAt,
    this.completedAt,
    required this.retryCount,
    this.error,
  });

  QueueRecord copyWith({
    QueueStatus? status,
    DateTime? completedAt,
    int? retryCount,
    String? error,
  }) {
    return QueueRecord(
      id: id,
      vin: vin,
      condicion: condicion,
      zonaInspeccion: zonaInspeccion,
      fotoPath: fotoPath,
      bloqueId: bloqueId,
      fila: fila,
      posicion: posicion,
      contenedorId: contenedorId,
      status: status ?? this.status,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      retryCount: retryCount ?? this.retryCount,
      error: error,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vin': vin,
      'condicion': condicion,
      'zona_inspeccion': zonaInspeccion,
      'foto_path': fotoPath,
      'bloque_id': bloqueId,
      'fila': fila,
      'posicion': posicion,
      'contenedor_id': contenedorId,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'retry_count': retryCount,
      'error': error,
    };
  }

  static QueueRecord fromJson(Map<String, dynamic> json) {
    return QueueRecord(
      id: json['id'],
      vin: json['vin'],
      condicion: json['condicion'],
      zonaInspeccion: json['zona_inspeccion'],
      fotoPath: json['foto_path'],
      bloqueId: json['bloque_id'],
      fila: json['fila'],
      posicion: json['posicion'],
      contenedorId: json['contenedor_id'],
      status: QueueStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => QueueStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      retryCount: json['retry_count'] ?? 0,
      error: json['error'],
    );
  }
}

class QueueSnapshot {
  final List<QueueRecord> allRecords;
  final int pendingCount;
  final int completedCount;
  final int failedCount;
  final DateTime lastUpdated;

  const QueueSnapshot({
    required this.allRecords,
    required this.pendingCount,
    required this.completedCount,
    required this.failedCount,
    required this.lastUpdated,
  });

  QueueSnapshot.empty()
    : allRecords = const [],
      pendingCount = 0,
      completedCount = 0,
      failedCount = 0,
      lastUpdated = DateTime(2024, 1, 1);

  factory QueueSnapshot.fromRecords(List<QueueRecord> records) {
    final pending = records
        .where((r) => r.status == QueueStatus.pending)
        .length;
    final completed = records
        .where((r) => r.status == QueueStatus.completed)
        .length;
    final failed = records.where((r) => r.status == QueueStatus.failed).length;

    return QueueSnapshot(
      allRecords: List.unmodifiable(records)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      pendingCount: pending,
      completedCount: completed,
      failedCount: failed,
      lastUpdated: DateTime.now(),
    );
  }

  int get totalCount => allRecords.length;
}

// ============================================================================
// SINGLETON GLOBAL
// ============================================================================
final queueService = QueueService();
