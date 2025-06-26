// lib/services/inventarios_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:stampcamera/services/http_service.dart';

class InventariosService {
  final _http = HttpService();
  static const String _storageKey = 'pending_inventarios';

  // ============================================================================
  // OPCIONES Y CONFIGURACIÓN
  // ============================================================================

  /// Obtener inventario previo por marca, modelo y versión
  /// Este método obtiene una "plantilla" basada en inventarios anteriores
  Future<InventarioOptions> getInventarioOptions({
    required int marcaId,
    required String modelo,
    String? version,
  }) async {
    try {
      final queryParams = {
        'marca_id': marcaId,
        'modelo': modelo,
        if (version != null) 'version': version,
      };

      final response = await _http.dio.get(
        '/api/v1/autos/inventarios-base/options/',
        queryParameters: queryParams,
      );

      return InventarioOptions.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener opciones de inventario: $e');
    }
  }

  // ============================================================================
  // MÉTODOS OFFLINE-FIRST
  // ============================================================================

  /// Crear/actualizar inventario offline-first
  /// Guarda inmediatamente en local y luego intenta sync
  Future<bool> createOrUpdateInventarioOfflineFirst({
    required int informacionUnidadId,
    required Map<String, dynamic> inventarioData,
    List<String>? imagePaths,
  }) async {
    try {
      // 1. Guardar inmediatamente en local
      await _saveToLocalQueue(
        informacionUnidadId: informacionUnidadId,
        inventarioData: inventarioData,
        imagePaths: imagePaths,
      );

      // 2. Intentar envío inmediato si hay conexión
      try {
        await createOrUpdateInventario(
          informacionUnidadId: informacionUnidadId,
          inventarioData: inventarioData,
        );

        // Si hay imágenes, crearlas
        if (imagePaths != null && imagePaths.isNotEmpty) {
          for (final imagePath in imagePaths) {
            await createInventarioImage(
              informacionUnidadId: informacionUnidadId,
              imagePath: imagePath,
            );
          }
        }

        // Si se envía exitosamente, marcar como completado
        await _markAsCompleted(informacionUnidadId);
        return true;
      } catch (e) {
        print('No se pudo enviar inmediatamente, se guardó en cola: $e');
        return true;
      }
    } catch (e) {
      print('Error al guardar inventario offline: $e');
      return false;
    }
  }

  /// Crear inventario con una sola imagen offline-first
  Future<bool> createInventarioWithImageOfflineFirst({
    required int informacionUnidadId,
    required Map<String, dynamic> inventarioData,
    required String imagePath,
    String? descripcionImagen,
  }) async {
    return createOrUpdateInventarioOfflineFirst(
      informacionUnidadId: informacionUnidadId,
      inventarioData: {
        ...inventarioData,
        if (descripcionImagen != null) '_imagen_descripcion': descripcionImagen,
      },
      imagePaths: [imagePath],
    );
  }

  // ============================================================================
  // MÉTODOS ONLINE (PARA SYNC)
  // ============================================================================

  /// Crear/actualizar inventario (método online para sync)
  /// Este endpoint hace upsert: create si no existe, update si existe
  Future<InventarioBase> createOrUpdateInventario({
    required int informacionUnidadId,
    required Map<String, dynamic> inventarioData,
  }) async {
    try {
      final payload = {
        'informacion_unidad': informacionUnidadId,
        ...inventarioData,
      };

      final response = await _http.dio.post(
        '/api/v1/autos/inventarios-base/',
        data: payload,
      );

      return InventarioBase.fromJson(response.data);
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
        throw Exception('Información de unidad no encontrada');
      }

      throw Exception('Error del servidor: ${e.response?.statusCode}');
    } catch (e) {
      throw Exception('Error al crear inventario: $e');
    }
  }

  /// Crear imagen de inventario
  Future<InventarioImagen> createInventarioImage({
    required int informacionUnidadId,
    required String imagePath,
    String? descripcion,
  }) async {
    try {
      final formData = FormData.fromMap({
        'informacion_unidad': informacionUnidadId,
        'imagen': await MultipartFile.fromFile(imagePath),
        if (descripcion != null) 'descripcion': descripcion,
      });

      final response = await _http.dio.post(
        '/api/v1/autos/inventarios-base-imagenes/',
        data: formData,
        options: Options(
          extra: {
            'file_paths': {'imagen': imagePath},
          },
        ),
      );

      return InventarioImagen.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear imagen de inventario: $e');
    }
  }

  /// Obtener inventario por información de unidad
  Future<InventarioBase?> getInventarioByUnidad(int informacionUnidadId) async {
    try {
      final response = await _http.dio.get(
        '/api/v1/autos/inventarios-base/',
        queryParameters: {'informacion_unidad_id': informacionUnidadId},
      );

      final results = response.data['results'] as List?;
      if (results != null && results.isNotEmpty) {
        return InventarioBase.fromJson(results.first);
      }

      return null;
    } catch (e) {
      throw Exception('Error al obtener inventario: $e');
    }
  }

  // ============================================================================
  // GESTIÓN DE COLA LOCAL
  // ============================================================================

  Future<void> _saveToLocalQueue({
    required int informacionUnidadId,
    required Map<String, dynamic> inventarioData,
    List<String>? imagePaths,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final id = const Uuid().v4();

    final registro = {
      'id': id,
      'informacion_unidad_id': informacionUnidadId,
      'inventario_data': inventarioData,
      'image_paths': imagePaths,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'pending',
      'retry_count': 0,
      'type': 'inventarios',
    };

    final existingJson = prefs.getString(_storageKey) ?? '[]';
    final existing = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    existing.add(registro);
    await prefs.setString(_storageKey, jsonEncode(existing));
  }

  Future<void> _markAsCompleted(int informacionUnidadId) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_storageKey) ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    for (var registro in registros) {
      if (registro['informacion_unidad_id'] == informacionUnidadId &&
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

  /// Obtener count de inventarios pendientes
  Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_storageKey) ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    return registros.where((r) => r['status'] == 'pending').length;
  }

  /// Procesar cola de inventarios pendientes
  Future<void> processPendingQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_storageKey) ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    final pending = registros
        .where((r) => r['status'] == 'pending' && (r['retry_count'] ?? 0) < 3)
        .toList();

    print('📋 Procesando ${pending.length} inventarios pendientes');

    for (var registro in pending) {
      try {
        // Extraer descripción de imagen si existe
        final inventarioData = Map<String, dynamic>.from(
          registro['inventario_data'],
        );
        final imagenDescripcion = inventarioData.remove('_imagen_descripcion');

        // Crear el inventario
        await createOrUpdateInventario(
          informacionUnidadId: registro['informacion_unidad_id'],
          inventarioData: inventarioData,
        );

        // Agregar imágenes si las hay
        final imagePaths = registro['image_paths'];
        if (imagePaths != null && imagePaths is List && imagePaths.isNotEmpty) {
          for (final imagePath in List<String>.from(imagePaths)) {
            await createInventarioImage(
              informacionUnidadId: registro['informacion_unidad_id'],
              imagePath: imagePath,
              descripcion: imagenDescripcion,
            );
          }
        }

        registro['status'] = 'completed';
        registro['completed_at'] = DateTime.now().toIso8601String();
        print(
          '✅ Inventario para unidad ${registro['informacion_unidad_id']} completado',
        );
      } catch (e) {
        registro['retry_count'] = (registro['retry_count'] ?? 0) + 1;
        print('❌ Error procesando inventario: $e');

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
      // Extraer descripción de imagen si existe
      final inventarioData = Map<String, dynamic>.from(
        registro['inventario_data'],
      );
      final imagenDescripcion = inventarioData.remove('_imagen_descripcion');

      // Crear el inventario
      await createOrUpdateInventario(
        informacionUnidadId: registro['informacion_unidad_id'],
        inventarioData: inventarioData,
      );

      // Agregar imágenes si las hay
      final imagePaths = registro['image_paths'];
      if (imagePaths != null && imagePaths is List && imagePaths.isNotEmpty) {
        for (final imagePath in List<String>.from(imagePaths)) {
          await createInventarioImage(
            informacionUnidadId: registro['informacion_unidad_id'],
            imagePath: imagePath,
            descripcion: imagenDescripcion,
          );
        }
      }

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

  /// Limpiar registros fallidos
  Future<void> clearFailedRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_storageKey) ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    final notFailed = registros.where((r) => r['status'] != 'failed').toList();
    await prefs.setString(_storageKey, jsonEncode(notFailed));
    print('✅ Registros fallidos de inventarios eliminados');
  }
}

// ============================================================================
// MODELOS DE DATOS PARA INVENTARIOS
// ============================================================================

class InventarioOptions {
  final Map<String, dynamic> inventarioPrevio;
  final List<CampoInventario> camposInventario;

  const InventarioOptions({
    required this.inventarioPrevio,
    required this.camposInventario,
  });

  factory InventarioOptions.fromJson(Map<String, dynamic> json) {
    return InventarioOptions(
      inventarioPrevio: json['inventario_previo'] ?? {},
      camposInventario:
          (json['campos_inventario'] as List?)
              ?.map((e) => CampoInventario.fromJson(e))
              .toList() ??
          [],
    );
  }

  /// Obtener valor por defecto para un campo específico
  dynamic getDefaultValue(String fieldName) {
    return inventarioPrevio[fieldName];
  }

  /// Verificar si un campo es requerido
  bool isFieldRequired(String fieldName) {
    final campo = camposInventario.firstWhere(
      (c) => c.name == fieldName,
      orElse: () => const CampoInventario(
        name: '',
        verboseName: '',
        type: 'CharField',
        required: false,
      ),
    );
    return campo.required;
  }

  /// Obtener campos de tipo específico
  List<CampoInventario> getFieldsByType(String type) {
    return camposInventario.where((c) => c.type == type).toList();
  }
}

class CampoInventario {
  final String name;
  final String verboseName;
  final String type; // 'IntegerField', 'CharField', etc.
  final bool required;
  final dynamic defaultValue;

  const CampoInventario({
    required this.name,
    required this.verboseName,
    required this.type,
    required this.required,
    this.defaultValue,
  });

  factory CampoInventario.fromJson(Map<String, dynamic> json) {
    return CampoInventario(
      name: json['name'],
      verboseName: json['verbose_name'],
      type: json['type'],
      required: json['required'] ?? false,
      defaultValue: json['default'],
    );
  }

  /// Verificar si es un campo numérico
  bool get isNumeric => type == 'IntegerField' || type == 'DecimalField';

  /// Verificar si es un campo de texto
  bool get isText => type == 'CharField' || type == 'TextField';

  /// Obtener widget hint para UI
  String get displayHint {
    if (isNumeric) {
      return 'Ingrese cantidad';
    } else if (isText) {
      return 'Ingrese texto';
    }
    return 'Ingrese valor';
  }
}

class InventarioBase {
  final int id;
  final int informacionUnidadId;
  final Map<String, dynamic> campos;
  final String? createAt;
  final String? createBy;
  final String? updateAt;
  final String? updateBy;
  final List<InventarioImagen> imagenes;

  const InventarioBase({
    required this.id,
    required this.informacionUnidadId,
    required this.campos,
    this.createAt,
    this.createBy,
    this.updateAt,
    this.updateBy,
    required this.imagenes,
  });

  factory InventarioBase.fromJson(Map<String, dynamic> json) {
    // Extraer campos dinámicos del inventario
    final campos = <String, dynamic>{};
    final excludedFields = {
      'id',
      'informacion_unidad',
      'create_at',
      'create_by',
      'update_at',
      'update_by',
      'imagenes',
    };

    for (final entry in json.entries) {
      if (!excludedFields.contains(entry.key)) {
        campos[entry.key] = entry.value;
      }
    }

    return InventarioBase(
      id: json['id'],
      informacionUnidadId: json['informacion_unidad'] is Map
          ? json['informacion_unidad']['id']
          : json['informacion_unidad'],
      campos: campos,
      createAt: json['create_at'],
      createBy: json['create_by'],
      updateAt: json['update_at'],
      updateBy: json['update_by'],
      imagenes:
          (json['imagenes'] as List?)
              ?.map((e) => InventarioImagen.fromJson(e))
              .toList() ??
          [],
    );
  }

  /// Obtener valor de un campo específico
  dynamic getCampoValue(String fieldName) {
    return campos[fieldName];
  }

  /// Verificar si tiene un campo específico
  bool hasCampo(String fieldName) {
    return campos.containsKey(fieldName);
  }

  /// Obtener campos numéricos con sus valores
  Map<String, int> get camposNumericos {
    final numericos = <String, int>{};
    for (final entry in campos.entries) {
      if (entry.value is int) {
        numericos[entry.key] = entry.value;
      }
    }
    return numericos;
  }

  /// Obtener campos de texto con sus valores
  Map<String, String> get camposTexto {
    final textos = <String, String>{};
    for (final entry in campos.entries) {
      if (entry.value is String) {
        textos[entry.key] = entry.value;
      }
    }
    return textos;
  }
}

class InventarioImagen {
  final int id;
  final String? descripcion;
  final String? imagenUrl;
  final String? imagenThumbnailUrl;
  final String? createAt;
  final String? createBy;

  const InventarioImagen({
    required this.id,
    this.descripcion,
    this.imagenUrl,
    this.imagenThumbnailUrl,
    this.createAt,
    this.createBy,
  });

  factory InventarioImagen.fromJson(Map<String, dynamic> json) {
    return InventarioImagen(
      id: json['id'],
      descripcion: json['descripcion'],
      imagenUrl: json['imagen_url'],
      imagenThumbnailUrl: json['imagen_thumbnail_url'],
      createAt: json['create_at'],
      createBy: json['create_by'],
    );
  }

  /// Verificar si tiene imagen válida
  bool get hasValidImage => imagenUrl != null && imagenUrl!.isNotEmpty;

  /// Obtener URL para mostrar (thumbnail si existe, sino la original)
  String? get displayUrl => imagenThumbnailUrl ?? imagenUrl;
}
