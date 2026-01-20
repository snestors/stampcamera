// lib/services/offline_sync_handler.dart
// Manejador de sincronizacion que conecta la cola offline con los servicios API
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/services/offline_first_queue.dart';
import 'package:stampcamera/services/autos/detalle_registro_service.dart';
import 'package:stampcamera/providers/autos/registro_detalle_provider.dart';

class OfflineSyncHandler {
  static final OfflineSyncHandler _instance = OfflineSyncHandler._internal();
  factory OfflineSyncHandler() => _instance;
  OfflineSyncHandler._internal();

  final DetalleRegistroService _service = DetalleRegistroService();
  ProviderContainer? _container;

  // ============================================================================
  // INICIALIZACION
  // ============================================================================

  void initialize(ProviderContainer container) {
    _container = container;

    // Configurar callbacks de sincronizacion
    offlineFirstQueue.onSyncRecord = _syncRecord;
    offlineFirstQueue.onRecordSynced = _onRecordSynced;
    offlineFirstQueue.onRecordFailed = _onRecordFailed;

    // Inicializar la cola
    offlineFirstQueue.initialize();

    debugPrint('OfflineSyncHandler inicializado');
  }

  // ============================================================================
  // SINCRONIZACION DE REGISTROS
  // ============================================================================

  Future<bool> _syncRecord(OfflineRecord record) async {
    debugPrint('OfflineSyncHandler: Sincronizando ${record.type.name} ID: ${record.id}');

    switch (record.type) {
      case OfflineRecordType.registroVin:
        return await _syncRegistroVin(record);
      case OfflineRecordType.fotoPresentacion:
        return await _syncFotoPresentacion(record);
      case OfflineRecordType.dano:
        return await _syncDano(record);
    }
  }

  // ============================================================================
  // SYNC: REGISTRO VIN
  // ============================================================================

  Future<bool> _syncRegistroVin(OfflineRecord record) async {
    try {
      final data = record.data;
      final fotoPath = record.filePaths.isNotEmpty ? record.filePaths.first : null;

      if (fotoPath == null || !await File(fotoPath).exists()) {
        debugPrint('OfflineSyncHandler: Foto no encontrada para RegistroVin');
        return false;
      }

      final result = await _service.createRegistroVin(
        vin: data['vin'] as String,
        condicion: data['condicion'] as String,
        zonaInspeccion: data['zona_inspeccion'] as int,
        fotoVin: File(fotoPath),
        bloque: data['bloque'] as int?,
        fila: data['fila'] as int?,
        posicion: data['posicion'] as int?,
        contenedorId: data['contenedor_id'] as int?,
      );

      // Verificar si fue exitoso
      if (result['success'] == true || result['data'] != null) {
        debugPrint('OfflineSyncHandler: RegistroVin sincronizado exitosamente');
        return true;
      } else {
        debugPrint('OfflineSyncHandler: RegistroVin fallo: $result');
        return false;
      }
    } catch (e) {
      debugPrint('OfflineSyncHandler: Error sync RegistroVin: $e');
      return false;
    }
  }

  // ============================================================================
  // SYNC: FOTO PRESENTACION
  // ============================================================================

  Future<bool> _syncFotoPresentacion(OfflineRecord record) async {
    try {
      final data = record.data;
      final fotoPath = record.filePaths.isNotEmpty ? record.filePaths.first : null;

      if (fotoPath == null || !await File(fotoPath).exists()) {
        debugPrint('OfflineSyncHandler: Foto no encontrada para FotoPresentacion');
        return false;
      }

      final result = await _service.createFoto(
        registroVinId: data['registro_vin_id'] as int,
        tipo: data['tipo'] as String,
        imagen: File(fotoPath),
        nDocumento: data['n_documento'] as String?,
      );

      // Verificar si fue exitoso
      if (result['success'] == true || result['data'] != null) {
        debugPrint('OfflineSyncHandler: FotoPresentacion sincronizada exitosamente');
        return true;
      } else {
        debugPrint('OfflineSyncHandler: FotoPresentacion fallo: $result');
        return false;
      }
    } catch (e) {
      debugPrint('OfflineSyncHandler: Error sync FotoPresentacion: $e');
      return false;
    }
  }

  // ============================================================================
  // SYNC: DANO
  // ============================================================================

  Future<bool> _syncDano(OfflineRecord record) async {
    try {
      final data = record.data;

      // Convertir paths a Files
      final imagenes = <File>[];
      for (final path in record.filePaths) {
        if (await File(path).exists()) {
          imagenes.add(File(path));
        }
      }

      // Convertir zonas de List<dynamic> a List<int>
      List<int>? zonas;
      if (data['zonas'] != null) {
        zonas = (data['zonas'] as List<dynamic>).cast<int>();
      }

      final result = await _service.createDanoWithFormData(
        registroVinId: data['registro_vin_id'] as int,
        tipoDano: data['tipo_dano'] as int,
        areaDano: data['area_dano'] as int,
        severidad: data['severidad'] as int,
        zonas: zonas,
        descripcion: data['descripcion'] as String?,
        responsabilidad: data['responsabilidad'] as int?,
        relevante: data['relevante'] as bool? ?? false,
        imagenes: imagenes.isNotEmpty ? imagenes : null,
        nDocumento: data['n_documento'] as int?,
      );

      // Verificar si fue exitoso
      if (result['success'] == true || result['data'] != null) {
        debugPrint('OfflineSyncHandler: Dano sincronizado exitosamente');
        return true;
      } else {
        debugPrint('OfflineSyncHandler: Dano fallo: $result');
        return false;
      }
    } catch (e) {
      debugPrint('OfflineSyncHandler: Error sync Dano: $e');
      return false;
    }
  }

  // ============================================================================
  // CALLBACKS
  // ============================================================================

  void _onRecordSynced(OfflineRecord record) {
    debugPrint('OfflineSyncHandler: Registro sincronizado - ${record.type.name}');

    // Refrescar el provider correspondiente si tenemos el VIN
    final vin = record.data['vin'] as String?;
    if (vin != null && _container != null) {
      debugPrint('OfflineSyncHandler: Refrescando datos para VIN: $vin');
      // Invalidar el provider para que recargue los datos del servidor
      _container!.invalidate(detalleRegistroProvider(vin));
    }
  }

  void _onRecordFailed(OfflineRecord record, String error) {
    debugPrint('OfflineSyncHandler: Registro fallo - ${record.type.name}: $error');
  }
}

// ============================================================================
// SINGLETON GLOBAL
// ============================================================================

final offlineSyncHandler = OfflineSyncHandler();
