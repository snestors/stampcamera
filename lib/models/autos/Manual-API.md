Manual de APIs - Sistema de Autos
Índice

Configuración General
APIs de Embarques
APIs de Registro General
APIs de Registro VIN
APIs de Fotos de Presentación
APIs de Daños
APIs de Contenedores
APIs de Inventarios Base
Códigos de Respuesta
Ejemplos de Implementación en Flutter

Configuración General
Base URL
https://tu-dominio.com/api/v1/autos/
Autenticación
Todas las APIs requieren autenticación. Incluir en los headers:
Authorization: Bearer <token>
Content-Type: application/json
Para endpoints con archivos:
Authorization: Bearer <token>
Content-Type: multipart/form-data

APIs de Embarques
1. Listar Embarques
Endpoint: GET /embarques/
Filtros disponibles:

nave_descarga_id: ID de la nave de descarga
search: Buscar por nombre de embarque o nombre de buque

Ejemplo de respuesta:
json{
  "count": 50,
  "results": [
    {
      "id": 1,
      "nombre_embarque": "EMBARQUE-001",
      "nave_descarga": {
        "id": 1,
        "nombre_buque": "MAERSK LIMA",
        "agente_naviero": {...},
        "puerto": {...}
      },
      "destinatario": {...},
      "marcas": [...],
      "documentos_autos": [...],
      "observaciones_embarque": [...]
    }
  ]
}
2. Obtener Embarque Específico
Endpoint: GET /embarques/{id}/

APIs de Registro General
1. Listar Registros VIN
Endpoint: GET /registro-general/
Filtros disponibles:

embarque_id: ID del embarque
search: Buscar por VIN o serie

Ejemplo de respuesta:
json{
  "count": 100,
  "results": [
    {
      "vin": "1HGBH41JXMN109186",
      "serie": "AB123456",
      "modelo": "COROLLA",
      "marca": "TOYOTA",
      "color": "BLANCO",
      "nave_descarga": "MAERSK LIMA",
      "bl": "BL123456",
      "pedeteado": true,
      "danos": false,
      "version": "XEI"
    }
  ]
}
2. Obtener Detalle de VIN
Endpoint: GET /registro-general/{vin}/
Respuesta incluye:

Información completa del vehículo
Registros VIN por condición
Fotos de presentación
Daños registrados


APIs de Registro VIN
1. Obtener Opciones Dinámicas
Endpoint: GET /registro-vin/options/
Respuesta:
json{
  "condiciones": [
    {"value": "PUERTO", "label": "Puerto"},
    {"value": "ALMACEN", "label": "Almacen"}
  ],
  "zonas_inspeccion": [
    {"value": 1, "label": "ZONA A"}
  ],
  "bloques": [
    {"value": 1, "label": "BLOQUE 1"}
  ],
  "field_permissions": {
    "condicion": {"editable": false, "required": true},
    "zona_inspeccion": {"editable": false, "required": true}
  },
  "initial_values": {
    "condicion": "PUERTO",
    "zona_inspeccion": 1
  },
  "vins_disponibles": [...],
  "contenedores_disponibles": [...]
}
2. Crear Registro VIN
Endpoint: POST /registro-vin/
Payload:
json{
  "vin": "1HGBH41JXMN109186",
  "condicion": "PUERTO",
  "zona_inspeccion": 1,
  "bloque": 1,
  "fila": 1,
  "posicion": 1,
  "foto_vin": "<archivo_imagen>"
}
Respuesta exitosa:
json{
  "id": 1,
  "vin": "1HGBH41JXMN109186",
  "condicion": "PUERTO",
  "zona_inspeccion": "ZONA A",
  "foto_vin_url": "https://...",
  "foto_vin_thumbnail_url": "https://...",
  "fecha": "25/06/2025 10:30",
  "create_by": "Juan Pérez"
}
3. Crear Registro VIN Completo
Endpoint: POST /registro-vin/create_complete/
Payload (multipart/form-data):
registro_vin_data[vin]: 1HGBH41JXMN109186
registro_vin_data[condicion]: PUERTO
registro_vin_data[zona_inspeccion]: 1
registro_vin_data[foto_vin]: <archivo>

fotos_presentacion[0][tipo]: AUTO
fotos_presentacion[0][imagen]: <archivo>
fotos_presentacion[0][n_documento]: DOC-001

danos[0][tipo_dano]: 1
danos[0][area_dano]: 2
danos[0][severidad]: 3
Respuesta:
json{
  "success": true,
  "message": "Registro creado exitosamente con 2 fotos y 1 daños",
  "data": {
    "registro_vin_id": 1,
    "fotos_creadas": 2,
    "danos_creados": 1
  }
}

APIs de Fotos de Presentación
1. Obtener Tipos de Documento
Endpoint: GET /fotos-presentacion/options/
Respuesta:
json{
  "tipos_disponibles": [
    {"value": "TARJA", "label": "Tarja"},
    {"value": "AUTO", "label": "Auto"},
    {"value": "DR", "label": "Damage Report"}
  ]
}
2. Crear Foto Individual
Endpoint: POST /fotos-presentacion/
Payload (multipart/form-data):
registro_vin: 1
tipo: AUTO
n_documento: DOC-001
imagen: <archivo>
3. Crear Múltiples Fotos
Endpoint: POST /fotos-presentacion/bulk_create/
Payload (multipart/form-data):
registro_vin: 1
imagen_0: <archivo1>
tipo_0: AUTO
n_documento_0: DOC-001
imagen_1: <archivo2>
tipo_1: TARJA
n_documento_1: DOC-002
Respuesta:
json{
  "success": true,
  "message": "2 fotos creadas exitosamente",
  "data": {
    "registro_vin_id": 1,
    "imagenes_creadas": 2,
    "imagenes": [
      {
        "id": 1,
        "tipo": "AUTO",
        "imagen_url": "https://...",
        "imagen_thumbnail_url": "https://..."
      }
    ]
  }
}

APIs de Daños
1. Obtener Opciones de Daños
Endpoint: GET /danos/options/
Respuesta:
json{
  "tipos_dano": [
    {"value": 1, "label": "Rayón"}
  ],
  "areas_dano": [
    {"value": 1, "label": "Puerta delantera izquierda"}
  ],
  "severidades": [
    {"value": 1, "label": "Leve"}
  ],
  "zonas_danos": [
    {"value": 1, "label": "Zona A"}
  ],
  "responsabilidades": [
    {"value": 1, "label": "SNMP"}
  ],
  "registros_vin_disponibles": [...]
}
2. Crear Daño
Endpoint: POST /danos/
Payload:
json{
  "registro_vin": 1,
  "tipo_dano": 1,
  "area_dano": 1,
  "severidad": 1,
  "zonas": [1, 2],
  "descripcion": "Rayón en la puerta",
  "responsabilidad": 1,
  "relevante": true
}
3. Agregar Imagen a Daño
Endpoint: POST /danos/{id}/add_image/
Payload (multipart/form-data):
imagen: <archivo>
4. Agregar Múltiples Imágenes
Endpoint: POST /danos/{id}/add_multiple_images/
Payload (multipart/form-data):
imagen_0: <archivo1>
imagen_1: <archivo2>
imagen_2: <archivo3>
5. Eliminar Imagen
Endpoint: DELETE /danos/{id}/remove_image/
Payload:
json{
  "imagen_id": 1
}

APIs de Contenedores
1. Obtener Opciones de Contenedores
Endpoint: GET /contenedores/options/
Respuesta:
json{
  "naves_disponibles": [
    {"id": 1, "nombre": "MAERSK LIMA"}
  ],
  "zonas_disponibles": [
    {"id": 1, "nombre": "ZONA A"}
  ],
  "field_permissions": {
    "n_contenedor": {"editable": true, "required": true},
    "nave_descarga": {"editable": false, "required": true}
  },
  "initial_values": {
    "nave_descarga": 1
  }
}
2. Crear Contenedor
Endpoint: POST /contenedores/
Payload (multipart/form-data):
n_contenedor: TCLU1234567
nave_descarga: 1
zona_inspeccion: 1
foto_contenedor: <archivo>
precinto1: ABC123
foto_precinto1: <archivo>

APIs de Inventarios Base
1. Obtener Inventario Previo
Endpoint: GET /inventarios-base/options/?marca_id=1&modelo=COROLLA&version=XEI
Respuesta:
json{
  "inventario_previo": {
    "LLAVE_SIMPLE": 2,
    "LLAVE_COMANDO": 1,
    "LLAVE_INTELIGENTE": 0,
    "ENCENDEDOR": 1,
    "MANUALES_ESTUCHE": 1,
    "LLANTA_DE_REPUESTO": 1,
    "OTROS": "Cable auxiliar"
  },
  "campos_inventario": [
    {
      "name": "LLAVE_SIMPLE",
      "verbose_name": "Llave Simple",
      "type": "IntegerField",
      "required": false,
      "default": 0
    }
  ]
}
2. Crear/Actualizar Inventario
Endpoint: POST /inventarios-base/
Payload:
json{
  "informacion_unidad": 1,
  "LLAVE_SIMPLE": 2,
  "LLAVE_COMANDO": 1,
  "LLAVE_INTELIGENTE": 0,
  "ENCENDEDOR": 1,
  "MANUALES_ESTUCHE": 1,
  "LLANTA_DE_REPUESTO": 1,
  "OTROS": "Cable auxiliar incluido"
}

Códigos de Respuesta
Códigos de Éxito

200 OK: Operación exitosa
201 Created: Recurso creado exitosamente

Códigos de Error

400 Bad Request: Datos inválidos
401 Unauthorized: Token inválido o ausente
403 Forbidden: Sin permisos para la operación
404 Not Found: Recurso no encontrado
500 Internal Server Error: Error del servidor

Formato de Errores
json{
  "success": false,
  "errors": {
    "field_name": ["Error message"]
  }
}
Para errores de validación global:
json{
  "non_field_errors": ["Error message"]
}

Ejemplos de Implementación en Flutter
1. Configuración del Cliente HTTP
dartclass ApiClient {
  static const String baseUrl = 'https://tu-dominio.com/api/v1/autos';
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static Map<String, String> get headers => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };

  static Map<String, String> get multipartHeaders => {
    'Authorization': 'Bearer $_token',
  };
}
2. Service para Registro VIN
dartclass RegistroVinService {
  
  // Obtener opciones dinámicas
  static Future<RegistroVinOptions> getOptions() async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/registro-vin/options/'),
      headers: ApiClient.headers,
    );

    if (response.statusCode == 200) {
      return RegistroVinOptions.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al obtener opciones');
    }
  }

  // Crear registro VIN
  static Future<RegistroVin> crearRegistro({
    required String vin,
    required String condicion,
    required int zonaInspeccion,
    File? fotoVin,
    int? bloque,
    int? fila,
    int? posicion,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiClient.baseUrl}/registro-vin/'),
    );

    request.headers.addAll(ApiClient.multipartHeaders);
    
    request.fields['vin'] = vin;
    request.fields['condicion'] = condicion;
    request.fields['zona_inspeccion'] = zonaInspeccion.toString();
    
    if (bloque != null) request.fields['bloque'] = bloque.toString();
    if (fila != null) request.fields['fila'] = fila.toString();
    if (posicion != null) request.fields['posicion'] = posicion.toString();

    if (fotoVin != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'foto_vin',
        fotoVin.path,
      ));
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      return RegistroVin.fromJson(jsonDecode(responseBody));
    } else {
      final error = jsonDecode(responseBody);
      throw Exception(error['non_field_errors']?.first ?? 'Error al crear registro');
    }
  }
}
3. Service para Fotos de Presentación
dartclass FotosService {
  
  // Crear múltiples fotos
  static Future<BulkCreateResponse> crearMultiplesFotos({
    required int registroVinId,
    required List<FotoData> fotos,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiClient.baseUrl}/fotos-presentacion/bulk_create/'),
    );

    request.headers.addAll(ApiClient.multipartHeaders);
    request.fields['registro_vin'] = registroVinId.toString();

    for (int i = 0; i < fotos.length; i++) {
      final foto = fotos[i];
      
      request.files.add(await http.MultipartFile.fromPath(
        'imagen_$i',
        foto.file.path,
      ));
      
      request.fields['tipo_$i'] = foto.tipo;
      request.fields['n_documento_$i'] = foto.nDocumento ?? '';
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      return BulkCreateResponse.fromJson(jsonDecode(responseBody));
    } else {
      throw Exception('Error al crear fotos');
    }
  }
}
4. Service para Daños
dartclass DanosService {
  
  // Crear daño
  static Future<Dano> crearDano({
    required int registroVinId,
    required int tipoDano,
    required int areaDano,
    required int severidad,
    List<int>? zonas,
    String? descripcion,
    int? responsabilidad,
    bool relevante = false,
  }) async {
    final Map<String, dynamic> payload = {
      'registro_vin': registroVinId,
      'tipo_dano': tipoDano,
      'area_dano': areaDano,
      'severidad': severidad,
      'relevante': relevante,
    };

    if (zonas != null) payload['zonas'] = zonas;
    if (descripcion != null) payload['descripcion'] = descripcion;
    if (responsabilidad != null) payload['responsabilidad'] = responsabilidad;

    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/danos/'),
      headers: ApiClient.headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      final result = jsonDecode(response.body);
      return Dano.fromJson(result['data']);
    } else {
      throw Exception('Error al crear daño');
    }
  }

  // Agregar imagen a daño
  static Future<ImagenDano> agregarImagen({
    required int danoId,
    required File imagen,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiClient.baseUrl}/danos/$danoId/add_image/'),
    );

    request.headers.addAll(ApiClient.multipartHeaders);
    
    request.files.add(await http.MultipartFile.fromPath(
      'imagen',
      imagen.path,
    ));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      final result = jsonDecode(responseBody);
      return ImagenDano.fromJson(result['data']);
    } else {
      throw Exception('Error al agregar imagen');
    }
  }
}
5. Manejo de Errores Centralizado
dartclass ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message;
}

class ApiErrorHandler {
  static void handleError(http.Response response) {
    final body = jsonDecode(response.body);
    
    switch (response.statusCode) {
      case 400:
        if (body['non_field_errors'] != null) {
          throw ApiException(body['non_field_errors'].first);
        } else if (body['errors'] != null) {
          throw ApiException(
            'Error de validación',
            statusCode: 400,
            errors: body['errors'],
          );
        }
        break;
      case 401:
        throw ApiException('Token inválido o expirado', statusCode: 401);
      case 403:
        throw ApiException('Sin permisos para esta operación', statusCode: 403);
      case 404:
        throw ApiException('Recurso no encontrado', statusCode: 404);
      default:
        throw ApiException('Error del servidor', statusCode: response.statusCode);
    }
  }
}
6. Modelos de Datos
dartclass RegistroVinOptions {
  final List<Opcion> condiciones;
  final List<Opcion> zonasInspeccion;
  final List<Opcion> bloques;
  final Map<String, FieldPermission> fieldPermissions;
  final Map<String, dynamic> initialValues;
  final List<VinDisponible> vinsDisponibles;

  RegistroVinOptions({
    required this.condiciones,
    required this.zonasInspeccion,
    required this.bloques,
    required this.fieldPermissions,
    required this.initialValues,
    required this.vinsDisponibles,
  });

  factory RegistroVinOptions.fromJson(Map<String, dynamic> json) {
    return RegistroVinOptions(
      condiciones: (json['condiciones'] as List)
          .map((e) => Opcion.fromJson(e))
          .toList(),
      zonasInspeccion: (json['zonas_inspeccion'] as List)
          .map((e) => Opcion.fromJson(e))
          .toList(),
      bloques: (json['bloques'] as List)
          .map((e) => Opcion.fromJson(e))
          .toList(),
      fieldPermissions: (json['field_permissions'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, FieldPermission.fromJson(v))),
      initialValues: json['initial_values'] ?? {},
      vinsDisponibles: (json['vins_disponibles'] as List)
          .map((e) => VinDisponible.fromJson(e))
          .toList(),
    );
  }
}

class Opcion {
  final String value;
  final String label;

  Opcion({required this.value, required this.label});

  factory Opcion.fromJson(Map<String, dynamic> json) {
    return Opcion(
      value: json['value'].toString(),
      label: json['label'],
    );
  }
}

class FieldPermission {
  final bool editable;
  final bool required;

  FieldPermission({required this.editable, required this.required});

  factory FieldPermission.fromJson(Map<String, dynamic> json) {
    return FieldPermission(
      editable: json['editable'] ?? true,
      required: json['required'] ?? false,
    );
  }
}

Notas Importantes

Permisos: Las opciones disponibles cambian según el usuario y su asistencia activa
Archivos: Usar multipart/form-data para endpoints que manejan imágenes
Validaciones: Siempre verificar las opciones disponibles antes de crear registros
Errores: Manejar tanto errores de campo como errores globales (non_field_errors)
Cache: Las opciones pueden cambiar según el contexto, no cachear indefinidamente