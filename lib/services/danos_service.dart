// lib/services/danos_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:stampcamera/services/http_service.dart';

class DanosService {
  final _http = HttpService();
  static const String _storageKey = 'pending_danos';

  // ============================================================================
  // OPCIONES Y CONFIGURACIÓN
  // ============================================================================

  /// Obtener opciones de daños (tipos, áreas, severidades, etc.)
  Future<DanosOptions> getOptions() async {
    try {
      final response = await _http.dio.get('/api/v1/autos/danos/options/');
      return DanosOptions.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener opciones de daños: $e');
    }
  }

  // ============================================================================
  // MÉTODOS OFFLINE-FIRST
  // ============================================================================

  /// Crear daño con imágenes offline-first
  Future<bool> createDanoOfflineFirst({
    required int registroVinId,
    required int tipoDano,
    required int areaDano,
    required int severidad,
    List<int>? zonas,
    String? descripcion,
    int? responsabilidad,
    bool relevante = false,
    List<String>? imagePaths, // Rutas de imágenes opcionales
  }) async {
    try {
      // 1. Guardar inmediatamente en local
      await _saveToLocalQueue(
        registroVinId: registroVinId,
        tipoDano: tipoDano,
        areaDano: areaDano,
        severidad: severidad,
        zonas: zonas,
        descripcion: descripcion,
        responsabilidad: responsabilidad,
        relevante: relevante,
        imagePaths: imagePaths,
      );

      // 2. Intentar envío inmediato si hay conexión
      try {
        final dano = await createDano(
          registroVinId: registroVinId,
          tipoDano: tipoDano,
          areaDano: areaDano,
          severidad: severidad,
          zonas: zonas,
          descripcion: descripcion,
          responsabilidad: responsabilidad,
          relevante: relevante,
        );

        // Si hay imágenes, agregarlas
        if (imagePaths != null && imagePaths.isNotEmpty) {
          await addMultipleImages(danoId: dano.id, imagePaths: imagePaths);
        }

        // Si se envía exitosamente, marcar como completado
        await _markAsCompleted(registroVinId);
        return true;
      } catch (e) {
        print('No se pudo enviar inmediatamente, se guardó en cola: $e');
        // No importa, ya está guardado localmente
        return true;
      }
    } catch (e) {
      print('Error al guardar daño offline: $e');
      return false;
    }
  }

  // ============================================================================
  // MÉTODOS ONLINE (PARA SYNC)
  // ============================================================================

  /// Crear daño (método online para sync)
  Future<Dano> createDano({
    required int registroVinId,
    required int tipoDano,
    required int areaDano,
    required int severidad,
    List<int>? zonas,
    String? descripcion,
    int? responsabilidad,
    bool relevante = false,
  }) async {
    try {
      final payload = {
        'registro_vin': registroVinId,
        'tipo_dano': tipoDano,
        'area_dano': areaDano,
        'severidad': severidad,
        'relevante': relevante,
        if (zonas != null) 'zonas': zonas,
        if (descripcion != null) 'descripcion': descripcion,
        if (responsabilidad != null) 'responsabilidad': responsabilidad,
      };

      final response = await _http.dio.post(
        '/api/v1/autos/danos/',
        data: payload,
      );

      // El API puede retornar directamente el daño o dentro de 'data'
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('data')) {
          return Dano.fromJson(responseData['data']);
        } else {
          return Dano.fromJson(responseData);
        }
      }

      throw Exception('Formato de respuesta inesperado');
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
      throw Exception('Error al crear daño: $e');
    }
  }

  /// Agregar múltiples imágenes a un daño
  Future<List<DanoImagen>> addMultipleImages({
    required int danoId,
    required List<String> imagePaths,
  }) async {
    try {
      final formData = FormData();

      // Agregar cada imagen con índice
      for (int i = 0; i < imagePaths.length; i++) {
        formData.files.add(
          MapEntry(
            'imagen_$i',
            await MultipartFile.fromFile(
              imagePaths[i],
              filename: imagePaths[i].split('/').last,
            ),
          ),
        );
      }

      final response = await _http.dio.post(
        '/api/v1/autos/danos/$danoId/add_multiple_images/',
        data: formData,
        options: Options(
          extra: {
            'file_paths': {
              for (int i = 0; i < imagePaths.length; i++)
                'imagen_$i': imagePaths[i],
            },
          },
        ),
      );

      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData['data'] != null) {
        final imagenesData = responseData['data']['imagenes'] as List?;
        return imagenesData?.map((e) => DanoImagen.fromJson(e)).toList() ?? [];
      }

      return [];
    } catch (e) {
      throw Exception('Error al agregar imágenes: $e');
    }
  }

  /// Agregar imagen individual a un daño
  Future<DanoImagen> addImage({
    required int danoId,
    required String imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'imagen': await MultipartFile.fromFile(imagePath),
      });

      final response = await _http.dio.post(
        '/api/v1/autos/danos/$danoId/add_image/',
        data: formData,
        options: Options(
          extra: {
            'file_paths': {'imagen': imagePath},
          },
        ),
      );

      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData['data'] != null) {
        return DanoImagen.fromJson(responseData['data']);
      }

      throw Exception('Formato de respuesta inesperado');
    } catch (e) {
      throw Exception('Error al agregar imagen: $e');
    }
  }

  /// Eliminar imagen de un daño
  Future<void> removeImage({required int danoId, required int imagenId}) async {
    try {
      await _http.dio.delete(
        '/api/v1/autos/danos/$danoId/remove_image/',
        data: {'imagen_id': imagenId},
      );
    } catch (e) {
      throw Exception('Error al eliminar imagen: $e');
    }
  }

  // ============================================================================
  // GESTIÓN DE COLA LOCAL
  // ============================================================================

  Future<void> _saveToLocalQueue({
    required int registroVinId,
    required int tipoDano,
    required int areaDano,
    required int severidad,
    List<int>? zonas,
    String? descripcion,
    int? responsabilidad,
    bool relevante = false,
    List<String>? imagePaths,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final id = const Uuid().v4();

    final registro = {
      'id': id,
      'registro_vin_id': registroVinId,
      'tipo_dano': tipoDano,
      'area_dano': areaDano,
      'severidad': severidad,
      'zonas': zonas,
      'descripcion': descripcion,
      'responsabilidad': responsabilidad,
      'relevante': relevante,
      'image_paths': imagePaths,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'pending',
      'retry_count': 0,
      'type': 'danos',
    };

    // Obtener registros existentes
    final existingJson = prefs.getString(_storageKey) ?? '[]';
    final existing = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    existing.add(registro);
    await prefs.setString(_storageKey, jsonEncode(existing));
  }

  Future<void> _markAsCompleted(int registroVinId) async {
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

  /// Obtener count de daños pendientes
  Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_storageKey) ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    return registros.where((r) => r['status'] == 'pending').length;
  }

  /// Procesar cola de daños pendientes
  Future<void> processPendingQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_storageKey) ?? '[]';
    final registros = List<Map<String, dynamic>>.from(jsonDecode(existingJson));

    final pending = registros
        .where((r) => r['status'] == 'pending' && (r['retry_count'] ?? 0) < 3)
        .toList();

    print('📋 Procesando ${pending.length} daños pendientes');

    for (var registro in pending) {
      try {
        // Crear el daño
        final dano = await createDano(
          registroVinId: registro['registro_vin_id'],
          tipoDano: registro['tipo_dano'],
          areaDano: registro['area_dano'],
          severidad: registro['severidad'],
          zonas: registro['zonas'] != null
              ? List<int>.from(registro['zonas'])
              : null,
          descripcion: registro['descripcion'],
          responsabilidad: registro['responsabilidad'],
          relevante: registro['relevante'] ?? false,
        );

        // Agregar imágenes si las hay
        final imagePaths = registro['image_paths'];
        if (imagePaths != null && imagePaths is List && imagePaths.isNotEmpty) {
          await addMultipleImages(
            danoId: dano.id,
            imagePaths: List<String>.from(imagePaths),
          );
        }

        // Marcar como completado
        registro['status'] = 'completed';
        registro['completed_at'] = DateTime.now().toIso8601String();
        print('✅ Daño para registro ${registro['registro_vin_id']} completado');
      } catch (e) {
        // Incrementar retry count
        registro['retry_count'] = (registro['retry_count'] ?? 0) + 1;
        print('❌ Error procesando daño: $e');

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
      // Crear el daño
      final dano = await createDano(
        registroVinId: registro['registro_vin_id'],
        tipoDano: registro['tipo_dano'],
        areaDano: registro['area_dano'],
        severidad: registro['severidad'],
        zonas: registro['zonas'] != null
            ? List<int>.from(registro['zonas'])
            : null,
        descripcion: registro['descripcion'],
        responsabilidad: registro['responsabilidad'],
        relevante: registro['relevante'] ?? false,
      );

      // Agregar imágenes si las hay
      final imagePaths = registro['image_paths'];
      if (imagePaths != null && imagePaths is List && imagePaths.isNotEmpty) {
        await addMultipleImages(
          danoId: dano.id,
          imagePaths: List<String>.from(imagePaths),
        );
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
}

// ============================================================================
// MODELOS DE DATOS PARA DAÑOS
// ============================================================================

class DanosOptions {
  final List<TipoDanoOption> tiposDano;
  final List<AreaDanoOption> areasDano;
  final List<SeveridadOption> severidades;
  final List<ZonaDanoOption> zonasDanos;
  final List<ResponsabilidadOption> responsabilidades;

  const DanosOptions({
    required this.tiposDano,
    required this.areasDano,
    required this.severidades,
    required this.zonasDanos,
    required this.responsabilidades,
  });

  factory DanosOptions.fromJson(Map<String, dynamic> json) {
    return DanosOptions(
      tiposDano:
          (json['tipos_dano'] as List?)
              ?.map((e) => TipoDanoOption.fromJson(e))
              .toList() ??
          [],
      areasDano:
          (json['areas_dano'] as List?)
              ?.map((e) => AreaDanoOption.fromJson(e))
              .toList() ??
          [],
      severidades:
          (json['severidades'] as List?)
              ?.map((e) => SeveridadOption.fromJson(e))
              .toList() ??
          [],
      zonasDanos:
          (json['zonas_danos'] as List?)
              ?.map((e) => ZonaDanoOption.fromJson(e))
              .toList() ??
          [],
      responsabilidades:
          (json['responsabilidades'] as List?)
              ?.map((e) => ResponsabilidadOption.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class TipoDanoOption {
  final int value;
  final String label;

  const TipoDanoOption({required this.value, required this.label});

  factory TipoDanoOption.fromJson(Map<String, dynamic> json) {
    return TipoDanoOption(value: json['value'], label: json['label']);
  }
}

class AreaDanoOption {
  final int value;
  final String label;

  const AreaDanoOption({required this.value, required this.label});

  factory AreaDanoOption.fromJson(Map<String, dynamic> json) {
    return AreaDanoOption(value: json['value'], label: json['label']);
  }
}

class SeveridadOption {
  final int value;
  final String label;

  const SeveridadOption({required this.value, required this.label});

  factory SeveridadOption.fromJson(Map<String, dynamic> json) {
    return SeveridadOption(value: json['value'], label: json['label']);
  }
}

class ZonaDanoOption {
  final int value;
  final String label;

  const ZonaDanoOption({required this.value, required this.label});

  factory ZonaDanoOption.fromJson(Map<String, dynamic> json) {
    return ZonaDanoOption(value: json['value'], label: json['label']);
  }
}

class ResponsabilidadOption {
  final int value;
  final String label;

  const ResponsabilidadOption({required this.value, required this.label});

  factory ResponsabilidadOption.fromJson(Map<String, dynamic> json) {
    return ResponsabilidadOption(value: json['value'], label: json['label']);
  }
}

class Dano {
  final int id;
  final String? descripcion;
  final String? condicion;
  final int tipoDano;
  final int areaDano;
  final int severidad;
  final List<int> zonas;
  final int? responsabilidad;
  final bool verificadoBool;
  final String? createAt;
  final String? createBy;
  final List<DanoImagen> imagenes;

  const Dano({
    required this.id,
    this.descripcion,
    this.condicion,
    required this.tipoDano,
    required this.areaDano,
    required this.severidad,
    required this.zonas,
    this.responsabilidad,
    required this.verificadoBool,
    this.createAt,
    this.createBy,
    required this.imagenes,
  });

  factory Dano.fromJson(Map<String, dynamic> json) {
    return Dano(
      id: json['id'],
      descripcion: json['descripcion'],
      condicion: json['condicion'],
      tipoDano: json['tipo_dano'],
      areaDano: json['area_dano'],
      severidad: json['severidad'],
      zonas: (json['zonas'] as List?)?.map((e) => e as int).toList() ?? [],
      responsabilidad: json['responsabilidad'],
      verificadoBool: json['verificado_bool'] ?? false,
      createAt: json['create_at'],
      createBy: json['create_by'],
      imagenes:
          (json['imagenes'] as List?)
              ?.map((e) => DanoImagen.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DanoImagen {
  final int id;
  final String? imagenUrl;
  final String? imagenThumbnailUrl;
  final String? createAt;

  const DanoImagen({
    required this.id,
    this.imagenUrl,
    this.imagenThumbnailUrl,
    this.createAt,
  });

  factory DanoImagen.fromJson(Map<String, dynamic> json) {
    return DanoImagen(
      id: json['id'],
      imagenUrl: json['imagen_url'],
      imagenThumbnailUrl: json['imagen_thumbnail_url'],
      createAt: json['create_at'],
    );
  }
}
