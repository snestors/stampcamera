// lib/models/autos/inventarios_model.dart
// 📋 MODELOS PARA INVENTARIOS
// ✅ Compatible con InventariosService
// ✅ Soporte para plantillas dinámicas
// ✅ Campos configurables desde backend

/// Modelo de opciones dinámicas de inventario por modelo/versión
class InventarioOptions {
  final String modelo;
  final String? version;
  final List<CampoInventario> campos;
  final InventarioConfiguracion configuracion;

  const InventarioOptions({
    required this.modelo,
    this.version,
    required this.campos,
    required this.configuracion,
  });

  factory InventarioOptions.fromJson(Map<String, dynamic> json) {
    return InventarioOptions(
      modelo: json['modelo'] as String,
      version: json['version'] as String?,
      campos:
          (json['campos'] as List<dynamic>?)
              ?.map((e) => CampoInventario.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      configuracion: InventarioConfiguracion.fromJson(
        json['configuracion'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modelo': modelo,
      if (version != null) 'version': version,
      'campos': campos.map((e) => e.toJson()).toList(),
      'configuracion': configuracion.toJson(),
    };
  }

  @override
  String toString() =>
      'InventarioOptions(modelo: $modelo, campos: ${campos.length})';
}

/// Tipos de campo disponibles para inventarios
enum CampoTipo {
  texto,
  numero,
  booleano,
  fecha,
  hora,
  fechaHora,
  email,
  telefono,
  url,
  seleccion,
  seleccionMultiple,
  area,
}

/// Modelo de campo dinámico de inventario
class CampoInventario {
  final String nombre;
  final CampoTipo tipo;
  final bool requerido;
  final String label;
  final List<String>? opciones; // Para campos de selección
  final dynamic valorPorDefecto;
  final String? placeholder;
  final CampoValidaciones? validaciones;

  const CampoInventario({
    required this.nombre,
    required this.tipo,
    required this.requerido,
    required this.label,
    this.opciones,
    this.valorPorDefecto,
    this.placeholder,
    this.validaciones,
  });

  factory CampoInventario.fromJson(Map<String, dynamic> json) {
    return CampoInventario(
      nombre: json['nombre'] as String,
      tipo: CampoTipo.values.firstWhere(
        (t) => t.name == json['tipo'],
        orElse: () => CampoTipo.texto,
      ),
      requerido: json['requerido'] as bool? ?? false,
      label: json['label'] as String,
      opciones: (json['opciones'] as List<dynamic>?)?.cast<String>(),
      valorPorDefecto: json['valor_por_defecto'],
      placeholder: json['placeholder'] as String?,
      validaciones: json['validaciones'] != null
          ? CampoValidaciones.fromJson(
              json['validaciones'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'tipo': tipo.name,
      'requerido': requerido,
      'label': label,
      if (opciones != null) 'opciones': opciones,
      if (valorPorDefecto != null) 'valor_por_defecto': valorPorDefecto,
      if (placeholder != null) 'placeholder': placeholder,
      if (validaciones != null) 'validaciones': validaciones!.toJson(),
    };
  }

  /// Verificar si es campo de selección
  bool get isSeleccion =>
      tipo == CampoTipo.seleccion || tipo == CampoTipo.seleccionMultiple;

  /// Verificar si requiere opciones
  bool get requiereOpciones => isSeleccion;

  @override
  String toString() =>
      'CampoInventario(nombre: $nombre, tipo: $tipo, requerido: $requerido)';
}

/// Validaciones para campos de inventario
class CampoValidaciones {
  final int? minLength;
  final int? maxLength;
  final double? min;
  final double? max;
  final String? patron;
  final String? mensajePatron;

  const CampoValidaciones({
    this.minLength,
    this.maxLength,
    this.min,
    this.max,
    this.patron,
    this.mensajePatron,
  });

  factory CampoValidaciones.fromJson(Map<String, dynamic> json) {
    return CampoValidaciones(
      minLength: json['min_length'] as int?,
      maxLength: json['max_length'] as int?,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      patron: json['patron'] as String?,
      mensajePatron: json['mensaje_patron'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (minLength != null) 'min_length': minLength,
      if (maxLength != null) 'max_length': maxLength,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      if (patron != null) 'patron': patron,
      if (mensajePatron != null) 'mensaje_patron': mensajePatron,
    };
  }

  @override
  String toString() =>
      'CampoValidaciones(minLength: $minLength, maxLength: $maxLength)';
}

/// Configuración del inventario
class InventarioConfiguracion {
  final bool permiteMultiplesInventarios;
  final bool requiereFotos;
  final int maxFotos;
  final List<String> tiposFotoPermitidos;

  const InventarioConfiguracion({
    required this.permiteMultiplesInventarios,
    required this.requiereFotos,
    required this.maxFotos,
    required this.tiposFotoPermitidos,
  });

  factory InventarioConfiguracion.fromJson(Map<String, dynamic> json) {
    return InventarioConfiguracion(
      permiteMultiplesInventarios:
          json['permite_multiples_inventarios'] as bool? ?? false,
      requiereFotos: json['requiere_fotos'] as bool? ?? false,
      maxFotos: json['max_fotos'] as int? ?? 10,
      tiposFotoPermitidos:
          (json['tipos_foto_permitidos'] as List<dynamic>?)?.cast<String>() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'permite_multiples_inventarios': permiteMultiplesInventarios,
      'requiere_fotos': requiereFotos,
      'max_fotos': maxFotos,
      'tipos_foto_permitidos': tiposFotoPermitidos,
    };
  }

  @override
  String toString() =>
      'InventarioConfiguracion(requiereFotos: $requiereFotos, maxFotos: $maxFotos)';
}

/// Modelo de inventario (response del backend)
class Inventario {
  final int id;
  final String vin;
  final String modelo;
  final String? version;
  final Map<String, dynamic> camposData;
  final String? createAt;
  final String? createBy;
  final List<InventarioFoto> fotos;

  const Inventario({
    required this.id,
    required this.vin,
    required this.modelo,
    this.version,
    required this.camposData,
    this.createAt,
    this.createBy,
    required this.fotos,
  });

  factory Inventario.fromJson(Map<String, dynamic> json) {
    return Inventario(
      id: json['id'] as int,
      vin: json['vin'] as String,
      modelo: json['modelo'] as String,
      version: json['version'] as String?,
      camposData: json['campos_data'] as Map<String, dynamic>? ?? {},
      createAt: json['create_at'] as String?,
      createBy: json['create_by'] as String?,
      fotos:
          (json['fotos'] as List<dynamic>?)
              ?.map((e) => InventarioFoto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vin': vin,
      'modelo': modelo,
      if (version != null) 'version': version,
      'campos_data': camposData,
      if (createAt != null) 'create_at': createAt,
      if (createBy != null) 'create_by': createBy,
      'fotos': fotos.map((e) => e.toJson()).toList(),
    };
  }

  /// Getter para verificar si tiene fotos
  bool get hasFotos => fotos.isNotEmpty;

  /// Getter para obtener número de fotos
  int get fotoCount => fotos.length;

  /// Getter para verificar si tiene versión específica
  bool get hasVersion => version != null && version!.isNotEmpty;

  /// Obtener valor de un campo específico
  T? getCampoValue<T>(String nombreCampo) {
    final value = camposData[nombreCampo];
    if (value is T) return value;
    return null;
  }

  /// Verificar si un campo tiene valor
  bool hasCampoValue(String nombreCampo) {
    return camposData.containsKey(nombreCampo) &&
        camposData[nombreCampo] != null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Inventario && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Inventario(id: $id, vin: $vin, modelo: $modelo, hasFotos: $hasFotos)';
}

/// Modelo de foto de inventario
class InventarioFoto {
  final int id;
  final String tipo;
  final String? imagenUrl;
  final String? imagenThumbnailUrl;
  final String? createAt;

  const InventarioFoto({
    required this.id,
    required this.tipo,
    this.imagenUrl,
    this.imagenThumbnailUrl,
    this.createAt,
  });

  factory InventarioFoto.fromJson(Map<String, dynamic> json) {
    return InventarioFoto(
      id: json['id'] as int,
      tipo: json['tipo'] as String,
      imagenUrl: json['imagen_url'] as String?,
      imagenThumbnailUrl: json['imagen_thumbnail_url'] as String?,
      createAt: json['create_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      if (imagenUrl != null) 'imagen_url': imagenUrl,
      if (imagenThumbnailUrl != null)
        'imagen_thumbnail_url': imagenThumbnailUrl,
      if (createAt != null) 'create_at': createAt,
    };
  }

  /// Getter para verificar si tiene imagen disponible
  bool get hasImage => imagenUrl != null && imagenUrl!.isNotEmpty;

  /// Getter para verificar si tiene thumbnail
  bool get hasThumbnail =>
      imagenThumbnailUrl != null && imagenThumbnailUrl!.isNotEmpty;

  /// Getter para URL de imagen a mostrar (thumbnail primero, luego imagen completa)
  String? get displayImageUrl => hasThumbnail ? imagenThumbnailUrl : imagenUrl;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventarioFoto && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'InventarioFoto(id: $id, tipo: $tipo, hasImage: $hasImage)';
}

/// Helper para validar tipos de campo
class CampoTipoHelper {
  static bool isNumeric(CampoTipo tipo) {
    return tipo == CampoTipo.numero;
  }

  static bool isText(CampoTipo tipo) {
    return [
      CampoTipo.texto,
      CampoTipo.email,
      CampoTipo.telefono,
      CampoTipo.url,
      CampoTipo.area,
    ].contains(tipo);
  }

  static bool isDate(CampoTipo tipo) {
    return [
      CampoTipo.fecha,
      CampoTipo.hora,
      CampoTipo.fechaHora,
    ].contains(tipo);
  }

  static bool isSelection(CampoTipo tipo) {
    return [CampoTipo.seleccion, CampoTipo.seleccionMultiple].contains(tipo);
  }

  static String getInputHint(CampoTipo tipo) {
    switch (tipo) {
      case CampoTipo.email:
        return 'ejemplo@correo.com';
      case CampoTipo.telefono:
        return '+1234567890';
      case CampoTipo.url:
        return 'https://ejemplo.com';
      case CampoTipo.numero:
        return 'Ingrese un número';
      case CampoTipo.fecha:
        return 'DD/MM/AAAA';
      case CampoTipo.hora:
        return 'HH:MM';
      case CampoTipo.fechaHora:
        return 'DD/MM/AAAA HH:MM';
      default:
        return 'Ingrese el valor';
    }
  }
}
