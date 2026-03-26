// services/registro_vin_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:stampcamera/models/autos/registro_vin_options.dart';
import 'package:stampcamera/models/autos/registro_general_model.dart';
import 'package:stampcamera/services/http_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:stampcamera/core/helpers/formatters/date_formatters.dart';

/// Excepción especial para registros duplicados - NO es un error real
class DuplicateRecordException implements Exception {
  final String vin;
  DuplicateRecordException(this.vin);

  @override
  String toString() => 'DuplicateRecordException: VIN $vin ya existe';
}

class RegistroVinService {
  final _http = HttpService();

  Future<RegistroVinOptions> getOptions() async {
    try {
      final response = await _http.dio.get(
        '/api/v1/autos/registro-vin/options/?registros=True',
      );
      return RegistroVinOptions.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener opciones: $e');
    }
  }

  Future<List<RegistroGeneral>> searchRegistros({
    String? search,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
      };

      final response = await _http.dio.get(
        '/api/v1/autos/registro-vin/',
        queryParameters: queryParams,
      );

      final results = response.data['results'] as List;
      return results.map((json) => RegistroGeneral.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error en búsqueda: $e');
    }
  }

  Future<RegistroGeneral> createRegistro({
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
      final formData = FormData.fromMap({
        'vin': vin,
        'condicion': condicion,
        'zona_inspeccion': zonaInspeccion,
        'foto_vin': await MultipartFile.fromFile(fotoPath),
        if (bloqueId != null) 'bloque': bloqueId,
        if (fila != null) 'fila': fila,
        if (posicion != null) 'posicion': posicion,
        if (contenedorId != null) 'contenedor': contenedorId,
      });

      final response = await _http.dio.post(
        '/api/v1/autos/registro-vin/',
        data: formData,
        options: Options(
          extra: {
            'file_paths': {'foto_vin': fotoPath},
          },
        ),
      );

      return RegistroGeneral.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;

        // Verificar si es error de duplicado - tratar como éxito
        if (_isDuplicateError(errorData)) {
          debugPrint('⚠️ VIN $vin ya existe - tratando como éxito');
          // Lanzar excepción especial para indicar duplicado (no es un error real)
          throw DuplicateRecordException(vin);
        }

        if (errorData is Map<String, dynamic> &&
            errorData.containsKey('non_field_errors')) {
          final nonFieldErrors = errorData['non_field_errors'];
          if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
            throw Exception(nonFieldErrors.first.toString());
          }
        }

        if (errorData is Map<String, dynamic>) {
          final firstError = _extractFirstFieldError(errorData);
          if (firstError != null) {
            throw Exception(firstError);
          }
        }

        throw Exception('Error de validación en los datos');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Sesión expirada, inicia sesión nuevamente');
      }

      throw Exception('Error del servidor (${e.response?.statusCode})');
    } catch (e) {
      // Re-lanzar DuplicateRecordException sin modificar
      if (e is DuplicateRecordException) rethrow;
      throw Exception('Error al crear registro: $e');
    }
  }

  /// Detecta si el error indica un registro duplicado
  bool _isDuplicateError(dynamic errorData) {
    if (errorData == null) return false;

    final errorString = errorData.toString().toLowerCase();

    // Detectar errores comunes de duplicado
    return errorString.contains('duplicado') ||
           errorString.contains('duplicate') ||
           errorString.contains('ya existe') ||
           errorString.contains('already exists') ||
           errorString.contains('unique constraint') ||
           errorString.contains('ya registrado') ||
           errorString.contains('already registered');
  }

  String? _extractFirstFieldError(Map<String, dynamic> errorData) {
    for (final entry in errorData.entries) {
      if (entry.key != 'non_field_errors' && entry.value is List) {
        final errors = entry.value as List;
        if (errors.isNotEmpty) {
          return '${entry.key}: ${errors.first}';
        }
      }
    }
    return null;
  }
}

// Extender la clase RegistroVinService existente
extension OfflineCapability on RegistroVinService {
  /// ✅ NUEVO MÉTODO: Guarda offline-first, envía en background
  Future<bool> createRegistroOfflineFirst({
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
      // 1. Guardar inmediatamente en local
      await _saveToLocalQueue(
        vin: vin,
        condicion: condicion,
        zonaInspeccion: zonaInspeccion,
        fotoPath: fotoPath,
        bloqueId: bloqueId,
        fila: fila,
        posicion: posicion,
        contenedorId: contenedorId,
      );

      // 2. Intentar envío inmediato si hay conexión
      try {
        await createRegistro(
          vin: vin,
          condicion: condicion,
          zonaInspeccion: zonaInspeccion,
          fotoPath: fotoPath,
          bloqueId: bloqueId,
          fila: fila,
          posicion: posicion,
          contenedorId: contenedorId,
        );

        // Si se envía exitosamente, marcar como completado
        await _markAsCompleted(vin);
      } catch (e) {
        debugPrint('No se pudo enviar inmediatamente, se guardó en cola: $e');
        // No importa, ya está guardado localmente
      }

      return true;
    } catch (e) {
      debugPrint('Error al guardar registro offline: $e');
      return false;
    }
  }

  /// Guarda el registro en cola local
  Future<void> _saveToLocalQueue({
    required String vin,
    required String condicion,
    required int zonaInspeccion,
    required String fotoPath,
    int? bloqueId,
    int? fila,
    int? posicion,
    int? contenedorId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final id = const Uuid().v4();

    final registro = {
      'id': id,
      'vin': vin,
      'condicion': condicion,
      'zona_inspeccion': zonaInspeccion,
      'foto_path': fotoPath,
      'bloque_id': bloqueId,
      'fila': fila,
      'posicion': posicion,
      'contenedor_id': contenedorId,
      'created_at': nowLima().toIso8601String(),
      'status': 'pending', // pending, completed, failed
      'retry_count': 0,
    };

    // Obtener registros existentes
    final existingJson = prefs.getString('pending_registros') ?? '[]';
    final existing = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    // Agregar nuevo registro
    existing.add(registro);

    // Guardar de vuelta
    await prefs.setString('pending_registros', jsonEncode(existing));
  }

  /// Marca un registro como completado
  Future<void> _markAsCompleted(String vin) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString('pending_registros') ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    // Buscar y marcar como completado
    for (var registro in registros) {
      if (registro['vin'] == vin && registro['status'] == 'pending') {
        registro['status'] = 'completed';
        registro['completed_at'] = nowLima().toIso8601String();
        break;
      }
    }

    await prefs.setString('pending_registros', jsonEncode(registros));
  }

  /// ✅ MÉTODO PÚBLICO: Obtener count de registros pendientes
  Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString('pending_registros') ?? '[]';
    debugPrint(existingJson);
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    return registros.where((r) => r['status'] == 'pending').length;
  }

  /// ✅ MÉTODO PÚBLICO: Procesar cola manualmente
  Future<void> processPendingQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString('pending_registros') ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    debugPrint('📊 Total registros: ${registros.length}');

    final pending = registros
        .where((r) => r['status'] == 'pending' && (r['retry_count'] ?? 0) < 3)
        .toList();

    debugPrint('📋 Registros para procesar: ${pending.length}');

    for (var registro in pending) {
      debugPrint(
        '🔄 Procesando: ${registro['vin']} - Retry: ${registro['retry_count']}',
      );

      try {
        await createRegistro(
          vin: registro['vin'],
          condicion: registro['condicion'],
          zonaInspeccion: registro['zona_inspeccion'],
          fotoPath: registro['foto_path'],
          bloqueId: registro['bloque_id'],
          fila: registro['fila'],
          posicion: registro['posicion'],
          contenedorId: registro['contenedor_id'],
        );

        // Marcar como completado
        registro['status'] = 'completed';
        registro['completed_at'] = nowLima().toIso8601String();
        debugPrint('✅ ${registro['vin']} completado');
      } on DuplicateRecordException {
        // Duplicado = ya existe en el servidor = éxito
        registro['status'] = 'completed';
        registro['completed_at'] = nowLima().toIso8601String();
        debugPrint('✅ ${registro['vin']} completado (ya existía en servidor)');
      } catch (e) {
        // Incrementar retry count
        registro['retry_count'] = (registro['retry_count'] ?? 0) + 1;
        debugPrint(
          '❌ ${registro['vin']} falló. Nuevo retry_count: ${registro['retry_count']}',
        );

        if (registro['retry_count'] >= 3) {
          registro['status'] = 'failed';
          registro['error'] = e.toString();
          debugPrint('🚫 ${registro['vin']} marcado como failed');
        }
      }
    }

    // Guardar cambios
    await prefs.setString('pending_registros', jsonEncode(registros));
  }

  /// ✅ MÉTODO PÚBLICO: Limpiar completados
  Future<void> clearCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString('pending_registros') ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    final notCompleted = registros
        .where((r) => r['status'] != 'completed')
        .toList();
    await prefs.setString('pending_registros', jsonEncode(notCompleted));
  }

  /// ✅ NUEVO MÉTODO: Obtener lista completa de registros pendientes
  Future<List<Map<String, dynamic>>> getPendingRecordsList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingJson = prefs.getString('pending_registros') ?? '[]';
      final registros = List<Map<String, dynamic>>.from(
        jsonDecode(existingJson),
      );

      // Ordenar por fecha de creación (más recientes primero)
      registros.sort((a, b) {
        final dateA = DateTime.parse(a['created_at']);
        final dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA);
      });

      return registros;
    } catch (e) {
      debugPrint('Error al obtener lista de registros: $e');
      return [];
    }
  }

  /// ✅ NUEVO MÉTODO: Reintentar un registro específico
  Future<void> retrySpecificRecord(String recordId) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString('pending_registros') ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    // Buscar el registro específico
    final recordIndex = registros.indexWhere((r) => r['id'] == recordId);
    if (recordIndex == -1) {
      throw Exception('Registro no encontrado');
    }

    final registro = registros[recordIndex];

    try {
      // Intentar envío
      await createRegistro(
        vin: registro['vin'],
        condicion: registro['condicion'],
        zonaInspeccion: registro['zona_inspeccion'],
        fotoPath: registro['foto_path'],
        bloqueId: registro['bloque_id'],
        fila: registro['fila'],
        posicion: registro['posicion'],
        contenedorId: registro['contenedor_id'],
      );

      // Si se envía exitosamente, marcar como completado
      registros[recordIndex]['status'] = 'completed';
      registros[recordIndex]['completed_at'] = nowLima().toIso8601String();
      registros[recordIndex]['error'] = null;
    } on DuplicateRecordException {
      // Duplicado = ya existe en el servidor = éxito
      registros[recordIndex]['status'] = 'completed';
      registros[recordIndex]['completed_at'] = nowLima().toIso8601String();
      registros[recordIndex]['error'] = null;
      debugPrint('✅ ${registro['vin']} completado (ya existía en servidor)');
    } catch (e) {
      // Si falla, incrementar retry count y actualizar error
      registros[recordIndex]['retry_count'] =
          (registro['retry_count'] ?? 0) + 1;
      registros[recordIndex]['error'] = e.toString();

      // Si supera los reintentos, marcar como failed
      if (registros[recordIndex]['retry_count'] >= 3) {
        registros[recordIndex]['status'] = 'failed';
      }

      rethrow; // Re-lanzar el error para que el UI lo maneje
    }

    // Guardar cambios
    await prefs.setString('pending_registros', jsonEncode(registros));
  }

  /// ✅ NUEVO MÉTODO: Eliminar todos los registros fallidos
  Future<void> clearFailedRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString('pending_registros') ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    // Filtrar solo los que NO están fallidos
    final notFailed = registros.where((r) => r['status'] != 'failed').toList();

    await prefs.setString('pending_registros', jsonEncode(notFailed));
    debugPrint('✅ Registros fallidos eliminados');
  }

  /// ✅ NUEVO MÉTODO: Eliminar un registro específico
  Future<void> deleteSpecificRecord(String recordId) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString('pending_registros') ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    // Filtrar todos excepto el que queremos eliminar
    final filtered = registros.where((r) => r['id'] != recordId).toList();

    await prefs.setString('pending_registros', jsonEncode(filtered));
    debugPrint('✅ Registro $recordId eliminado');
  }
}
