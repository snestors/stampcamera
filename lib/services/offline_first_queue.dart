// lib/services/offline_first_queue.dart
// Sistema de cola offline-first generico para guardar registros localmente
// y sincronizarlos en segundo plano sin esperar respuesta del servidor.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ============================================================================
// TIPOS DE REGISTRO
// ============================================================================

enum OfflineRecordType {
  registroVin,
  fotoPresentacion,
  dano,
}

enum OfflineRecordStatus {
  pending,
  syncing,
  completed,
  failed,
}

// ============================================================================
// MODELO DE REGISTRO OFFLINE
// ============================================================================

class OfflineRecord {
  final String id;
  final OfflineRecordType type;
  final Map<String, dynamic> data;
  final List<String> filePaths; // Rutas de archivos locales
  final OfflineRecordStatus status;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final int retryCount;
  final String? error;

  const OfflineRecord({
    required this.id,
    required this.type,
    required this.data,
    this.filePaths = const [],
    required this.status,
    required this.createdAt,
    this.syncedAt,
    this.retryCount = 0,
    this.error,
  });

  OfflineRecord copyWith({
    OfflineRecordStatus? status,
    DateTime? syncedAt,
    int? retryCount,
    String? error,
  }) {
    return OfflineRecord(
      id: id,
      type: type,
      data: data,
      filePaths: filePaths,
      status: status ?? this.status,
      createdAt: createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      retryCount: retryCount ?? this.retryCount,
      error: error,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'data': data,
      'file_paths': filePaths,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
      'retry_count': retryCount,
      'error': error,
    };
  }

  static OfflineRecord fromJson(Map<String, dynamic> json) {
    return OfflineRecord(
      id: json['id'],
      type: OfflineRecordType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OfflineRecordType.registroVin,
      ),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      filePaths: List<String>.from(json['file_paths'] ?? []),
      status: OfflineRecordStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OfflineRecordStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at']),
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'])
          : null,
      retryCount: json['retry_count'] ?? 0,
      error: json['error'],
    );
  }
}

// ============================================================================
// SERVICIO DE COLA OFFLINE-FIRST
// ============================================================================

class OfflineFirstQueue {
  static final OfflineFirstQueue _instance = OfflineFirstQueue._internal();
  factory OfflineFirstQueue() => _instance;
  OfflineFirstQueue._internal();

  static const String _storageKey = 'offline_first_queue';
  static const int _maxRetries = 3;

  final StreamController<OfflineQueueState> _stateController =
      StreamController<OfflineQueueState>.broadcast();

  Timer? _syncTimer;
  bool _isSyncing = false;

  // Adaptive backoff para el timer de sincronización
  static const Duration _minInterval = Duration(seconds: 10);
  static const Duration _maxInterval = Duration(seconds: 120);
  Duration _currentInterval = _minInterval;

  // Callbacks para sincronizacion - se configuran desde fuera
  Future<bool> Function(OfflineRecord record)? onSyncRecord;
  void Function(OfflineRecord record)? onRecordSynced;
  void Function(OfflineRecord record, String error)? onRecordFailed;

  // Stream publico para UI
  Stream<OfflineQueueState> get stateStream => _stateController.stream;

  // ============================================================================
  // INICIALIZACION
  // ============================================================================

  Future<void> initialize() async {
    await _emitCurrentState();
    _startAutoSync();
    _listenToConnectivity();
    debugPrint('OfflineFirstQueue inicializado');
  }

  void dispose() {
    _syncTimer?.cancel();
    _stateController.close();
  }

  // ============================================================================
  // OPERACIONES PRINCIPALES
  // ============================================================================

  /// Agregar registro a la cola (retorna inmediatamente)
  Future<String> addRecord({
    required OfflineRecordType type,
    required Map<String, dynamic> data,
    List<String> filePaths = const [],
  }) async {
    final record = OfflineRecord(
      id: const Uuid().v4(),
      type: type,
      data: data,
      filePaths: filePaths,
      status: OfflineRecordStatus.pending,
      createdAt: DateTime.now(),
    );

    final records = await _getAllRecords();
    records.add(record);
    await _saveAllRecords(records);
    await _emitCurrentState();

    debugPrint('OfflineFirstQueue: Registro agregado (${type.name}) ID: ${record.id}');

    // Intentar sync inmediato si hay conexion
    _tryImmediateSync();

    return record.id;
  }

  /// Obtener estado actual de la cola
  Future<OfflineQueueState> getCurrentState() async {
    final records = await _getAllRecords();
    return OfflineQueueState.fromRecords(records);
  }

  /// Forzar sincronizacion
  Future<void> forceSync() async {
    if (_isSyncing) return;
    await _syncPendingRecords();
  }

  /// Eliminar registro de la cola
  Future<void> removeRecord(String recordId) async {
    final records = await _getAllRecords();
    records.removeWhere((r) => r.id == recordId);
    await _saveAllRecords(records);
    await _emitCurrentState();
  }

  /// Limpiar registros completados
  Future<void> clearCompleted() async {
    final records = await _getAllRecords();
    final filtered = records
        .where((r) => r.status != OfflineRecordStatus.completed)
        .toList();
    await _saveAllRecords(filtered);
    await _emitCurrentState();
  }

  /// Reintentar registro fallido
  Future<void> retryRecord(String recordId) async {
    final records = await _getAllRecords();
    final index = records.indexWhere((r) => r.id == recordId);

    if (index != -1) {
      records[index] = records[index].copyWith(
        status: OfflineRecordStatus.pending,
        error: null,
      );
      await _saveAllRecords(records);
      await _emitCurrentState();
      _tryImmediateSync();
    }
  }

  // ============================================================================
  // SINCRONIZACION AUTOMATICA
  // ============================================================================

  void _startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer(_currentInterval, () async {
      await _syncPendingRecords();
      // Si se sincronizó algo, resetear intervalo; si no, backoff
      final records = await _getAllRecords();
      final hasPending = records.any(
        (r) => r.status == OfflineRecordStatus.pending && r.retryCount < _maxRetries,
      );
      if (hasPending) {
        _currentInterval = _minInterval;
      } else {
        _currentInterval = Duration(
          seconds: (_currentInterval.inSeconds * 2).clamp(
            _minInterval.inSeconds,
            _maxInterval.inSeconds,
          ),
        );
      }
      _startAutoSync(); // Re-programar con nuevo intervalo
    });
  }

  void _tryImmediateSync() {
    _currentInterval = _minInterval; // Resetear backoff
    if (!_isSyncing) {
      Future.delayed(const Duration(milliseconds: 500), _syncPendingRecords);
    }
  }

  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) async {
      if (!results.contains(ConnectivityResult.none)) {
        debugPrint('OfflineFirstQueue: Conectividad restaurada, sincronizando...');
        await Future.delayed(const Duration(seconds: 2));
        _syncPendingRecords();
      }
    });
  }

  Future<void> _syncPendingRecords() async {
    if (_isSyncing || onSyncRecord == null) return;

    // Verificar conectividad
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      debugPrint('OfflineFirstQueue: Sin conexion, saltando sync');
      return;
    }

    _isSyncing = true;

    try {
      final records = await _getAllRecords();
      final pending = records
          .where((r) =>
              r.status == OfflineRecordStatus.pending &&
              r.retryCount < _maxRetries)
          .toList();

      if (pending.isEmpty) {
        debugPrint('OfflineFirstQueue: No hay registros pendientes');
        return;
      }

      debugPrint('OfflineFirstQueue: Sincronizando ${pending.length} registros...');

      bool hasChanges = false;

      for (int i = 0; i < records.length; i++) {
        final record = records[i];

        if (record.status != OfflineRecordStatus.pending ||
            record.retryCount >= _maxRetries) {
          continue;
        }

        // Verificar que los archivos existan
        bool filesExist = true;
        for (final path in record.filePaths) {
          if (!await File(path).exists()) {
            filesExist = false;
            debugPrint('OfflineFirstQueue: Archivo no existe: $path');
            break;
          }
        }

        if (!filesExist) {
          records[i] = record.copyWith(
            status: OfflineRecordStatus.failed,
            error: 'Archivos no encontrados',
          );
          hasChanges = true;
          continue;
        }

        // Marcar como syncing
        records[i] = record.copyWith(status: OfflineRecordStatus.syncing);
        await _saveAllRecords(records);
        await _emitCurrentState();

        try {
          final success = await onSyncRecord!(record);

          if (success) {
            records[i] = record.copyWith(
              status: OfflineRecordStatus.completed,
              syncedAt: DateTime.now(),
              error: null,
            );
            hasChanges = true;
            debugPrint('OfflineFirstQueue: Registro ${record.id} sincronizado');
            onRecordSynced?.call(records[i]);
          } else {
            final newRetryCount = record.retryCount + 1;
            records[i] = record.copyWith(
              status: newRetryCount >= _maxRetries
                  ? OfflineRecordStatus.failed
                  : OfflineRecordStatus.pending,
              retryCount: newRetryCount,
              error: 'Sync fallido',
            );
            hasChanges = true;
            debugPrint('OfflineFirstQueue: Registro ${record.id} fallo (retry: $newRetryCount)');
          }
        } catch (e) {
          final newRetryCount = record.retryCount + 1;
          records[i] = record.copyWith(
            status: newRetryCount >= _maxRetries
                ? OfflineRecordStatus.failed
                : OfflineRecordStatus.pending,
            retryCount: newRetryCount,
            error: e.toString(),
          );
          hasChanges = true;
          debugPrint('OfflineFirstQueue: Error sync ${record.id}: $e');
          onRecordFailed?.call(records[i], e.toString());
        }
      }

      if (hasChanges) {
        await _saveAllRecords(records);
        await _emitCurrentState();
      }
    } catch (e) {
      debugPrint('OfflineFirstQueue: Error en sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ============================================================================
  // STORAGE
  // ============================================================================

  Future<List<OfflineRecord>> _getAllRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey) ?? '[]';
      final List<dynamic> list = jsonDecode(json);
      return list.map((item) => OfflineRecord.fromJson(item)).toList();
    } catch (e) {
      debugPrint('OfflineFirstQueue: Error loading records: $e');
      return [];
    }
  }

  Future<void> _saveAllRecords(List<OfflineRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(records.map((r) => r.toJson()).toList());
      await prefs.setString(_storageKey, json);
    } catch (e) {
      debugPrint('OfflineFirstQueue: Error saving records: $e');
    }
  }

  Future<void> _emitCurrentState() async {
    final state = await getCurrentState();
    _stateController.add(state);
  }
}

// ============================================================================
// ESTADO DE LA COLA
// ============================================================================

class OfflineQueueState {
  final List<OfflineRecord> allRecords;
  final int pendingCount;
  final int syncingCount;
  final int completedCount;
  final int failedCount;
  final DateTime lastUpdated;

  const OfflineQueueState({
    required this.allRecords,
    required this.pendingCount,
    required this.syncingCount,
    required this.completedCount,
    required this.failedCount,
    required this.lastUpdated,
  });

  OfflineQueueState.empty()
      : allRecords = const [],
        pendingCount = 0,
        syncingCount = 0,
        completedCount = 0,
        failedCount = 0,
        lastUpdated = DateTime(2024, 1, 1);

  factory OfflineQueueState.fromRecords(List<OfflineRecord> records) {
    final pending = records
        .where((r) => r.status == OfflineRecordStatus.pending)
        .length;
    final syncing = records
        .where((r) => r.status == OfflineRecordStatus.syncing)
        .length;
    final completed = records
        .where((r) => r.status == OfflineRecordStatus.completed)
        .length;
    final failed = records
        .where((r) => r.status == OfflineRecordStatus.failed)
        .length;

    // Ordenar antes de hacer inmutable
    final sortedRecords = List<OfflineRecord>.from(records)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return OfflineQueueState(
      allRecords: List.unmodifiable(sortedRecords),
      pendingCount: pending,
      syncingCount: syncing,
      completedCount: completed,
      failedCount: failed,
      lastUpdated: DateTime.now(),
    );
  }

  int get totalCount => allRecords.length;
  bool get hasPending => pendingCount > 0 || syncingCount > 0;
}

// ============================================================================
// SINGLETON GLOBAL
// ============================================================================

final offlineFirstQueue = OfflineFirstQueue();
