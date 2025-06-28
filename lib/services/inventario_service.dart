// services/inventario_service.dart
import 'package:dio/dio.dart';
import 'package:stampcamera/models/autos/inventario_model.dart';
import 'package:stampcamera/services/http_service.dart';

class InventarioService {
  final _http = HttpService();

  /// Obtener opciones de inventario con datos previos
  Future<InventarioOptions> getOptions({
    int? marcaId,
    String? modelo,
    String? version,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (marcaId != null) queryParams['marca_id'] = marcaId;
      if (modelo != null && modelo.isNotEmpty) queryParams['modelo'] = modelo;
      if (version != null && version.isNotEmpty)
        queryParams['version'] = version;

      final response = await _http.dio.get(
        '/api/v1/autos/inventarios-base/options/',
        queryParameters: queryParams,
      );

      return InventarioOptions.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener opciones de inventario: $e');
    }
  }

  /// Listar inventarios con filtros
  Future<List<InventarioBase>> searchInventarios({
    int? informacionUnidadId,
    String? search,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (informacionUnidadId != null)
          'informacion_unidad_id': informacionUnidadId,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
      };

      final response = await _http.dio.get(
        '/api/v1/autos/inventarios-base/',
        queryParameters: queryParams,
      );

      final results = response.data['results'] as List;
      return results.map((json) => InventarioBase.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error en búsqueda de inventarios: $e');
    }
  }

  /// Obtener inventario por información de unidad
  Future<InventarioBase?> getInventarioByUnidad(int informacionUnidadId) async {
    try {
      final inventarios = await searchInventarios(
        informacionUnidadId: informacionUnidadId,
      );

      return inventarios.isNotEmpty ? inventarios.first : null;
    } catch (e) {
      throw Exception('Error al obtener inventario: $e');
    }
  }

  /// Crear o actualizar inventario usando un mapa de datos
  Future<InventarioBase> createOrUpdateInventario({
    required int informacionUnidadId,
    required Map<String, dynamic> inventarioData,
  }) async {
    try {
      final data = {
        'informacion_unidad': informacionUnidadId,
        ...inventarioData,
      };

      final response = await _http.dio.post(
        '/api/v1/autos/inventarios-base/',
        data: data,
      );

      return InventarioBase.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          final message =
              errorData['non_field_errors']?.first ??
              _extractFirstFieldError(errorData) ??
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

  /// Crear inventario desde un objeto InventarioBase
  Future<InventarioBase> createFromInventarioBase(
    InventarioBase inventario,
  ) async {
    final inventarioData = {
      'LLAVE_SIMPLE': inventario.llaveSimple,
      'LLAVE_COMANDO': inventario.llaveComando,
      'LLAVE_INTELIGENTE': inventario.llaveInteligente,
      'ENCENDEDOR': inventario.encendedor,
      'CENICERO': inventario.cenicero,
      'CABLE_USB_O_AUX': inventario.cableUsbOAux,
      'RETROVISOR': inventario.retrovisor,
      'PISOS': inventario.pisos,
      'LOGOS': inventario.logos,
      'ESTUCHE_MANUAL': inventario.estucheManual,
      'MANUALES_ESTUCHE': inventario.manualesEstuche,
      'PIN_DE_REMOLQUE': inventario.pinDeRemolque,
      'TAPA_PIN_DE_REMOLQUE': inventario.tapaPinDeRemolque,
      'PORTAPLACA': inventario.portaplaca,
      'COPAS_TAPAS_DE_AROS': inventario.copasTapasDeAros,
      'TAPONES_CHASIS': inventario.tapones,
      'COBERTOR': inventario.cobertor,
      'BOTIQUIN': inventario.botiquin,
      'PERNO_SEGURO_RUEDA': inventario.pernoSeguroRueda,
      'AMBIENTADORES': inventario.ambientadores,
      'ESTUCHE_HERRAMIENTA': inventario.estucheHerramienta,
      'DESARMADOR': inventario.desarmador,
      'LLAVE_BOCA_COMBINADA': inventario.llaveBocaCombinada,
      'ALICATE': inventario.alicate,
      'LLAVE_DE_RUEDA': inventario.llaveDeRueda,
      'PALANCA_DE_GATA': inventario.palancaDeGata,
      'GATA': inventario.gata,
      'LLANTA_DE_REPUESTO': inventario.llantaDeRepuesto,
      'TRIANGULO_DE_EMERGENCIA': inventario.trianguloDeEmergencia,
      'MALLA': inventario.malla,
      'ANTENA': inventario.antena,
      'EXTRA': inventario.extra,
      'CABLE_CARGADOR': inventario.cableCargador,
      'CAJA_DE_FUSIBLES': inventario.cajaDeFusibles,
      'EXTINTOR': inventario.extintor,
      'CHALECO_REFLECTIVO': inventario.chalecoReflectivo,
      'CONOS': inventario.conos,
      'EXTENSION': inventario.extension,
      'OTROS': inventario.otros,
    };

    return await createOrUpdateInventario(
      informacionUnidadId: inventario.informacionUnidad.id,
      inventarioData: inventarioData,
    );
  }

  /// Actualizar inventario existente
  Future<InventarioBase> updateInventario({
    required int inventarioId,
    required Map<String, dynamic> inventarioData,
  }) async {
    try {
      final response = await _http.dio.patch(
        '/api/v1/autos/inventarios-base/$inventarioId/',
        data: inventarioData,
      );

      return InventarioBase.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al actualizar inventario: $e');
    }
  }

  /// Eliminar inventario
  Future<void> deleteInventario(int inventarioId) async {
    try {
      await _http.dio.delete('/api/v1/autos/inventarios-base/$inventarioId/');
    } catch (e) {
      throw Exception('Error al eliminar inventario: $e');
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
      );

      return InventarioImagen.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear imagen de inventario: $e');
    }
  }

  /// Listar imágenes de inventario
  Future<List<InventarioImagen>> getInventarioImages(
    int informacionUnidadId,
  ) async {
    try {
      final response = await _http.dio.get(
        '/api/v1/autos/inventarios-base-imagenes/',
        queryParameters: {'informacion_unidad_id': informacionUnidadId},
      );

      final results = response.data['results'] as List;
      return results.map((json) => InventarioImagen.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener imágenes: $e');
    }
  }

  /// Eliminar imagen de inventario
  Future<void> deleteInventarioImage(int imageId) async {
    try {
      await _http.dio.delete(
        '/api/v1/autos/inventarios-base-imagenes/$imageId/',
      );
    } catch (e) {
      throw Exception('Error al eliminar imagen: $e');
    }
  }

  /// Extraer primer error de campo para mostrar al usuario
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
