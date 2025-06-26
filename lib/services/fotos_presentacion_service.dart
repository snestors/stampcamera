// lib/services/fotos_presentacion_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:stampcamera/services/http_service.dart';

class FotosPresentacionService {
  final _http = HttpService();
  static const String _storageKey = 'pending_fotos_presentacion';

  // ============================================================================
  // OPCIONES Y CONFIGURACIÓN
  // ============================================================================

  /// Obtener tipos de documento disponibles
  Future<FotosOptions> getOptions() async {
    try {
      final response = await _http.dio.get(
        '/api/v1/autos/fotos-presentacion/options/',
      );
      return FotosOptions.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener opciones de fotos: $e');
    }
  }

  // ============================================================================
  // MÉTODOS OFFLINE-FIRST
  // ============================================================================

  /// Crear múltiples fotos offline-first
  Future<bool> createMultipleFotosOfflineFirst({
    required int registroVinId,
    required List<FotoCreate> fotos,
  }) async {
    try {
      // 1. Guardar inmediatamente en local
      await _saveToLocalQueue(registroVinId: registroVinId, fotos: fotos);

      // 2. Intentar envío inmediato si hay conexión
      try {
        final result = await createMultipleFotos(
          registroVinId: registroVinId,
          fotos: fotos,
        );

        // Si se envía exitosamente, marcar como completado
        await _markAsCompleted(registroVinId, fotos);
        return true;
      } catch (e) {
        print('No se pudo enviar inmediatamente, se guardó en cola: $e');
        // No importa, ya está guardado localmente
        return true;
      }
    } catch (e) {
      print('Error al guardar fotos offline: $e');
      return false;
    }
  }

  /// Crear foto individual offline-first
  Future<bool> createFotoOfflineFirst({
    required int registroVinId,
    required String tipo,
    required String imagenPath,
    String? nDocumento,
  }) async {
    final foto = FotoCreate(
      tipo: tipo,
      imagenPath: imagenPath,
      nDocumento: nDocumento,
    );

    return createMultipleFotosOfflineFirst(
      registroVinId: registroVinId,
      fotos: [foto],
    );
  }

  // ============================================================================
  // MÉTODOS ONLINE (PARA SYNC)
  // ============================================================================

  /// Crear múltiples fotos (método online para sync)
  Future<BulkCreateResponse> createMultipleFotos({
    required int registroVinId,
    required List<FotoCreate> fotos,
  }) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('registro_vin', registroVinId.toString()));

      // Agregar cada foto con índice
      for (int i = 0; i < fotos.length; i++) {
        final foto = fotos[i];

        // Agregar archivo
        formData.files.add(
          MapEntry(
            'imagen_$i',
            await MultipartFile.fromFile(
              foto.imagenPath,
              filename: foto.imagenPath.split('/').last,
            ),
          ),
        );

        // Agregar campos
        formData.fields.add(MapEntry('tipo_$i', foto.tipo));
        if (foto.nDocumento != null) {
          formData.fields.add(MapEntry('n_documento_$i', foto.nDocumento!));
        }
      }

      final response = await _http.dio.post(
        '/api/v1/autos/fotos-presentacion/bulk_create/',
        data: formData,
        options: Options(
          extra: {
            'file_paths': {
              for (int i = 0; i < fotos.length; i++)
                'imagen_$i': fotos[i].imagenPath,
            },
          },
        ),
      );

      return BulkCreateResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          final message =
              errorData['message'] ??
              errorData['non_field_errors']?.first ??
              'Error de validación';
          throw Exception(message);
        }
      }

      if (e.response?.statusCode == 404) {
        throw Exception('Registro VIN no encontrado');
      }

      throw Exception('Error del servidor: ${e.response?.statusCode}');
    } catch (e) {
      throw Exception('Error al crear fotos: $e');
    }
  }

  /// Crear foto individual (método online)
  Future<FotoPresentacion> createFoto({
    required int registroVinId,
    required String tipo,
    required String imagenPath,
    String? nDocumento,
  }) async {
    try {
      final formData = FormData.fromMap({
        'registro_vin': registroVinId,
        'tipo': tipo,
        'imagen': await MultipartFile.fromFile(imagenPath),
        if (nDocumento != null) 'n_documento': nDocumento,
      });

      final response = await _http.dio.post(
        '/api/v1/autos/fotos-presentacion/',
        data: formData,
        options: Options(
          extra: {
            'file_paths': {'imagen': imagenPath},
          },
        ),
      );

      return FotoPresentacion.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear foto: $e');
    }
  }

  // ============================================================================
  // GESTIÓN DE COLA LOCAL
  // ============================================================================

  Future<void> _saveToLocalQueue({
    required int registroVinId,
    required List<FotoCreate> fotos,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final id = const Uuid().v4();

    final registro = {
      'id': id,
      'registro_vin_id': registroVinId,
      'fotos': fotos.map((f) => f.toJson()).toList(),
      'created_at': DateTime.now().toIso8601String(),
      'status': 'pending',
      'retry_count': 0,
      'type': 'fotos_presentacion',
    };

    // Obtener registros existentes
    final existingJson = prefs.getString(_storageKey) ?? '[]';
    final existing = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    existing.add(registro);
    await prefs.setString(_storageKey, jsonEncode(existing));
  }

  Future<void> _markAsCompleted(
    int registroVinId,
    List<FotoCreate> fotos,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_storageKey) ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    // Buscar y marcar como completado
    for (var registro in registros) {
      if (registro['registro_vin_id'] == registroVinId &&
          registro['status'] == 'pending') {
        registro['status'] = 'completed';
        registro['completed_at'] = DateTime.now().toIso8601String();
        break;
      }
    }

    await prefs.setString(_storageKey, jsonEncode(registros));
  }

  // ============================================================================
  // MÉTODOS PÚBLICOS PARA QUEUE MANAGEMENT
  // ============================================================================

  /// Obtener count de fotos pendientes
  Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_storageKey) ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    return registros.where((r) => r['status'] == 'pending').length;
  }

  /// Procesar cola de fotos pendientes
  Future<void> processPendingQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_storageKey) ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    final pending = registros
        .where((r) => r['status'] == 'pending' && (r['retry_count'] ?? 0) < 3)
        .toList();

    print('📋 Procesando ${pending.length} registros de fotos pendientes');

    for (var registro in pending) {
      try {
        final registroVinId = registro['registro_vin_id'] as int;
        final fotosData = registro['fotos'] as List;
        final fotos = fotosData.map((f) => FotoCreate.fromJson(f)).toList();

        await createMultipleFotos(registroVinId: registroVinId, fotos: fotos);

        // Marcar como completado
        registro['status'] = 'completed';
        registro['completed_at'] = DateTime.now().toIso8601String();
        print('✅ Fotos para registro $registroVinId completadas');
      } catch (e) {
        // Incrementar retry count
        registro['retry_count'] = (registro['retry_count'] ?? 0) + 1;
        print('❌ Error procesando fotos: $e');

        if (registro['retry_count'] >= 3) {
          registro['status'] = 'failed';
          registro['error'] = e.toString();
        }
      }
    }

    await prefs.setString(_storageKey, jsonEncode(registros));
  }

  /// Obtener lista de registros pendientes
  Future<List<Map<String, dynamic>>> getPendingRecordsList() async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_storageKey) ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    registros.sort((a, b) {
      final dateA = DateTime.parse(a['created_at']);
      final dateB = DateTime.parse(b['created_at']);
      return dateB.compareTo(dateA);
    });

    return registros;
  }

  /// Reintentar registro específico
  Future<void> retrySpecificRecord(String recordId) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_storageKey) ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    final recordIndex = registros.indexWhere((r) => r['id'] == recordId);
    if (recordIndex == -1) {
      throw Exception('Registro no encontrado');
    }

    final registro = registros[recordIndex];

    try {
      final registroVinId = registro['registro_vin_id'] as int;
      final fotosData = registro['fotos'] as List;
      final fotos = fotosData.map((f) => FotoCreate.fromJson(f)).toList();

      await createMultipleFotos(registroVinId: registroVinId, fotos: fotos);

      registros[recordIndex]['status'] = 'completed';
      registros[recordIndex]['completed_at'] = DateTime.now().toIso8601String();
      registros[recordIndex]['error'] = null;
    } catch (e) {
      registros[recordIndex]['retry_count'] =
          (registro['retry_count'] ?? 0) + 1;
      registros[recordIndex]['error'] = e.toString();

      if (registros[recordIndex]['retry_count'] >= 3) {
        registros[recordIndex]['status'] = 'failed';
      }

      rethrow;
    }

    await prefs.setString(_storageKey, jsonEncode(registros));
  }

  /// Limpiar registros completados
  Future<void> clearCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_storageKey) ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    final notCompleted = registros
        .where((r) => r['status'] != 'completed')
        .toList();

    await prefs.setString(_storageKey, jsonEncode(notCompleted));
  }

  /// Eliminar registro específico
  Future<void> deleteSpecificRecord(String recordId) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_storageKey) ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    final filtered = registros.where((r) => r['id'] != recordId).toList();
    await prefs.setString(_storageKey, jsonEncode(filtered));
  }
}

// ============================================================================
// MODELOS DE DATOS
// ============================================================================

class FotoCreate {
  final String tipo;
  final String imagenPath;
  final String? nDocumento;

  const FotoCreate({
    required this.tipo,
    required this.imagenPath,
    this.nDocumento,
  });

  Map<String, dynamic> toJson() {
    return {'tipo': tipo, 'imagen_path': imagenPath, 'n_documento': nDocumento};
  }

  factory FotoCreate.fromJson(Map<String, dynamic> json) {
    return FotoCreate(
      tipo: json['tipo'],
      imagenPath: json['imagen_path'],
      nDocumento: json['n_documento'],
    );
  }
}

class FotosOptions {
  final List<TipoFotoOption> tiposDisponibles;

  const FotosOptions({required this.tiposDisponibles});

  factory FotosOptions.fromJson(Map<String, dynamic> json) {
    return FotosOptions(
      tiposDisponibles:
          (json['tipos_disponibles'] as List?)
              ?.map((e) => TipoFotoOption.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class TipoFotoOption {
  final String value;
  final String label;

  const TipoFotoOption({required this.value, required this.label});

  factory TipoFotoOption.fromJson(Map<String, dynamic> json) {
    return TipoFotoOption(value: json['value'], label: json['label']);
  }
}

class BulkCreateResponse {
  final bool success;
  final String message;
  final BulkCreateData data;

  const BulkCreateResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory BulkCreateResponse.fromJson(Map<String, dynamic> json) {
    return BulkCreateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: BulkCreateData.fromJson(json['data'] ?? {}),
    );
  }
}

class BulkCreateData {
  final int registroVinId;
  final int imagenesCreadas;
  final List<FotoPresentacion> imagenes;

  const BulkCreateData({
    required this.registroVinId,
    required this.imagenesCreadas,
    required this.imagenes,
  });

  factory BulkCreateData.fromJson(Map<String, dynamic> json) {
    return BulkCreateData(
      registroVinId: json['registro_vin_id'] ?? 0,
      imagenesCreadas: json['imagenes_creadas'] ?? 0,
      imagenes:
          (json['imagenes'] as List?)
              ?.map((e) => FotoPresentacion.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class FotoPresentacion {
  final int id;
  final String tipo;
  final String? nDocumento;
  final String? imagenUrl;
  final String? imagenThumbnailUrl;
  final String? createAt;
  final String? createBy;

  const FotoPresentacion({
    required this.id,
    required this.tipo,
    this.nDocumento,
    this.imagenUrl,
    this.imagenThumbnailUrl,
    this.createAt,
    this.createBy,
  });

  factory FotoPresentacion.fromJson(Map<String, dynamic> json) {
    return FotoPresentacion(
      id: json['id'],
      tipo: json['tipo'],
      nDocumento: json['n_documento'],
      imagenUrl: json['imagen_url'],
      imagenThumbnailUrl: json['imagen_thumbnail_url'],
      createAt: json['create_at'],
      createBy: json['create_by'],
    );
  }
}
