// lib/services/contenedores_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:stampcamera/services/http_service.dart';

class ContenedoresService {
  final _http = HttpService();
  static const String _storageKey = 'pending_contenedores';

  // ============================================================================
  // OPCIONES Y CONFIGURACIÓN
  // ============================================================================

  /// Obtener opciones de contenedores
  Future<ContenedoresOptions> getOptions() async {
    try {
      final response = await _http.dio.get(
        '/api/v1/autos/contenedores/options/',
      );
      return ContenedoresOptions.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener opciones de contenedores: $e');
    }
  }

  // ============================================================================
  // MÉTODOS OFFLINE-FIRST
  // ============================================================================

  /// Crear contenedor offline-first
  Future<bool> createContenedorOfflineFirst({
    required String nContenedor,
    required int naveDescarga,
    int? zonaInspeccion,
    String? fotoContenedorPath,
    String? precinto1,
    String? fotoPrecinto1Path,
    String? precinto2,
    String? fotoPrecinto2Path,
  }) async {
    try {
      // 1. Guardar inmediatamente en local
      await _saveToLocalQueue(
        nContenedor: nContenedor,
        naveDescarga: naveDescarga,
        zonaInspeccion: zonaInspeccion,
        fotoContenedorPath: fotoContenedorPath,
        precinto1: precinto1,
        fotoPrecinto1Path: fotoPrecinto1Path,
        precinto2: precinto2,
        fotoPrecinto2Path: fotoPrecinto2Path,
      );

      // 2. Intentar envío inmediato si hay conexión
      try {
        await createContenedor(
          nContenedor: nContenedor,
          naveDescarga: naveDescarga,
          zonaInspeccion: zonaInspeccion,
          fotoContenedorPath: fotoContenedorPath,
          precinto1: precinto1,
          fotoPrecinto1Path: fotoPrecinto1Path,
          precinto2: precinto2,
          fotoPrecinto2Path: fotoPrecinto2Path,
        );

        // Si se envía exitosamente, marcar como completado
        await _markAsCompleted(nContenedor);
        return true;
      } catch (e) {
        print('No se pudo enviar inmediatamente, se guardó en cola: $e');
        return true;
      }
    } catch (e) {
      print('Error al guardar contenedor offline: $e');
      return false;
    }
  }

  // ============================================================================
  // MÉTODOS ONLINE (PARA SYNC)
  // ============================================================================

  /// Crear contenedor (método online para sync)
  Future<Contenedor> createContenedor({
    required String nContenedor,
    required int naveDescarga,
    int? zonaInspeccion,
    String? fotoContenedorPath,
    String? precinto1,
    String? fotoPrecinto1Path,
    String? precinto2,
    String? fotoPrecinto2Path,
  }) async {
    try {
      final formData = FormData.fromMap({
        'n_contenedor': nContenedor,
        'nave_descarga': naveDescarga,
        if (zonaInspeccion != null) 'zona_inspeccion': zonaInspeccion,
        if (precinto1 != null) 'precinto1': precinto1,
        if (precinto2 != null) 'precinto2': precinto2,
      });

      // Agregar fotos si existen
      final filePaths = <String, String>{};

      if (fotoContenedorPath != null) {
        formData.files.add(
          MapEntry(
            'foto_contenedor',
            await MultipartFile.fromFile(fotoContenedorPath),
          ),
        );
        filePaths['foto_contenedor'] = fotoContenedorPath;
      }

      if (fotoPrecinto1Path != null) {
        formData.files.add(
          MapEntry(
            'foto_precinto1',
            await MultipartFile.fromFile(fotoPrecinto1Path),
          ),
        );
        filePaths['foto_precinto1'] = fotoPrecinto1Path;
      }

      if (fotoPrecinto2Path != null) {
        formData.files.add(
          MapEntry(
            'foto_precinto2',
            await MultipartFile.fromFile(fotoPrecinto2Path),
          ),
        );
        filePaths['foto_precinto2'] = fotoPrecinto2Path;
      }

      final response = await _http.dio.post(
        '/api/v1/autos/contenedores/',
        data: formData,
        options: Options(extra: {'file_paths': filePaths}),
      );

      return Contenedor.fromJson(response.data);
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

      throw Exception('Error del servidor: ${e.response?.statusCode}');
    } catch (e) {
      throw Exception('Error al crear contenedor: $e');
    }
  }

  // ============================================================================
  // GESTIÓN DE COLA LOCAL
  // ============================================================================

  Future<void> _saveToLocalQueue({
    required String nContenedor,
    required int naveDescarga,
    int? zonaInspeccion,
    String? fotoContenedorPath,
    String? precinto1,
    String? fotoPrecinto1Path,
    String? precinto2,
    String? fotoPrecinto2Path,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final id = const Uuid().v4();

    final registro = {
      'id': id,
      'n_contenedor': nContenedor,
      'nave_descarga': naveDescarga,
      'zona_inspeccion': zonaInspeccion,
      'foto_contenedor_path': fotoContenedorPath,
      'precinto1': precinto1,
      'foto_precinto1_path': fotoPrecinto1Path,
      'precinto2': precinto2,
      'foto_precinto2_path': fotoPrecinto2Path,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'pending',
      'retry_count': 0,
      'type': 'contenedores',
    };

    final existingJson = prefs.getString(_storageKey) ?? '[]';
    final existing = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    existing.add(registro);
    await prefs.setString(_storageKey, jsonEncode(existing));
  }

  Future<void> _markAsCompleted(String nContenedor) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_storageKey) ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    for (var registro in registros) {
      if (registro['n_contenedor'] == nContenedor &&
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

  /// Obtener count de contenedores pendientes
  Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_storageKey) ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    return registros.where((r) => r['status'] == 'pending').length;
  }

  /// Procesar cola de contenedores pendientes
  Future<void> processPendingQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_storageKey) ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    final pending = registros
        .where((r) => r['status'] == 'pending' && (r['retry_count'] ?? 0) < 3)
        .toList();

    print('📋 Procesando ${pending.length} contenedores pendientes');

    for (var registro in pending) {
      try {
        await createContenedor(
          nContenedor: registro['n_contenedor'],
          naveDescarga: registro['nave_descarga'],
          zonaInspeccion: registro['zona_inspeccion'],
          fotoContenedorPath: registro['foto_contenedor_path'],
          precinto1: registro['precinto1'],
          fotoPrecinto1Path: registro['foto_precinto1_path'],
          precinto2: registro['precinto2'],
          fotoPrecinto2Path: registro['foto_precinto2_path'],
        );

        registro['status'] = 'completed';
        registro['completed_at'] = DateTime.now().toIso8601String();
        print('✅ Contenedor ${registro['n_contenedor']} completado');
      } catch (e) {
        registro['retry_count'] = (registro['retry_count'] ?? 0) + 1;
        print('❌ Error procesando contenedor: $e');

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
      await createContenedor(
        nContenedor: registro['n_contenedor'],
        naveDescarga: registro['nave_descarga'],
        zonaInspeccion: registro['zona_inspeccion'],
        fotoContenedorPath: registro['foto_contenedor_path'],
        precinto1: registro['precinto1'],
        fotoPrecinto1Path: registro['foto_precinto1_path'],
        precinto2: registro['precinto2'],
        fotoPrecinto2Path: registro['foto_precinto2_path'],
      );

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
// MODELOS DE DATOS PARA CONTENEDORES
// ============================================================================

class ContenedoresOptions {
  final List<NaveDisponible> navesDisponibles;
  final List<ZonaDisponible> zonasDisponibles;
  final Map<String, FieldPermission> fieldPermissions;
  final Map<String, dynamic> initialValues;

  const ContenedoresOptions({
    required this.navesDisponibles,
    required this.zonasDisponibles,
    required this.fieldPermissions,
    required this.initialValues,
  });

  factory ContenedoresOptions.fromJson(Map<String, dynamic> json) {
    return ContenedoresOptions(
      navesDisponibles:
          (json['naves_disponibles'] as List?)
              ?.map((e) => NaveDisponible.fromJson(e))
              .toList() ??
          [],
      zonasDisponibles:
          (json['zonas_disponibles'] as List?)
              ?.map((e) => ZonaDisponible.fromJson(e))
              .toList() ??
          [],
      fieldPermissions:
          (json['field_permissions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, FieldPermission.fromJson(value)),
          ) ??
          {},
      initialValues: json['initial_values'] ?? {},
    );
  }
}

class NaveDisponible {
  final int id;
  final String nombre;

  const NaveDisponible({required this.id, required this.nombre});

  factory NaveDisponible.fromJson(Map<String, dynamic> json) {
    return NaveDisponible(id: json['id'], nombre: json['nombre']);
  }
}

class ZonaDisponible {
  final int id;
  final String nombre;

  const ZonaDisponible({required this.id, required this.nombre});

  factory ZonaDisponible.fromJson(Map<String, dynamic> json) {
    return ZonaDisponible(id: json['id'], nombre: json['nombre']);
  }
}

class Contenedor {
  final int id;
  final String nContenedor;
  final String naveDescarga;
  final String? zonaInspeccion;
  final String? fotoContenedorUrl;
  final String? precinto1;
  final String? fotoPrecinto1Url;
  final String? precinto2;
  final String? fotoPrecinto2Url;
  final String? createAt;
  final String? createBy;

  const Contenedor({
    required this.id,
    required this.nContenedor,
    required this.naveDescarga,
    this.zonaInspeccion,
    this.fotoContenedorUrl,
    this.precinto1,
    this.fotoPrecinto1Url,
    this.precinto2,
    this.fotoPrecinto2Url,
    this.createAt,
    this.createBy,
  });

  factory Contenedor.fromJson(Map<String, dynamic> json) {
    return Contenedor(
      id: json['id'],
      nContenedor: json['n_contenedor'],
      naveDescarga: json['nave_descarga'],
      zonaInspeccion: json['zona_inspeccion'],
      fotoContenedorUrl: json['foto_contenedor_url'],
      precinto1: json['precinto1'],
      fotoPrecinto1Url: json['foto_precinto1_url'],
      precinto2: json['precinto2'],
      fotoPrecinto2Url: json['foto_precinto2_url'],
      createAt: json['create_at'],
      createBy: json['create_by'],
    );
  }
}

class FieldPermission {
  final bool editable;
  final bool required;

  const FieldPermission({required this.editable, required this.required});

  factory FieldPermission.fromJson(Map<String, dynamic> json) {
    return FieldPermission(
      editable: json['editable'] ?? false,
      required: json['required'] ?? false,
    );
  }
}
