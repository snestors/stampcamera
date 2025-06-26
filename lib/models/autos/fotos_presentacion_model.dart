// lib/models/autos/fotos_presentacion_model.dart
// 📸 MODELOS PARA FOTOS DE PRESENTACIÓN
// ✅ Compatible con FotosPresentacionService
// ✅ Serialización JSON optimizada
// ✅ Modelos tanto para request como response

/// Modelo para crear una foto (usado en request)
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
    return {
      'tipo': tipo,
      'imagen_path': imagenPath,
      if (nDocumento != null) 'n_documento': nDocumento,
    };
  }

  factory FotoCreate.fromJson(Map<String, dynamic> json) {
    return FotoCreate(
      tipo: json['tipo'] as String,
      imagenPath: json['imagen_path'] as String,
      nDocumento: json['n_documento'] as String?,
    );
  }

  @override
  String toString() =>
      'FotoCreate(tipo: $tipo, imagenPath: $imagenPath, nDocumento: $nDocumento)';
}

/// Modelo de opciones disponibles (response del endpoint /options)
class FotosOptions {
  final List<TipoFotoOption> tiposDisponibles;

  const FotosOptions({required this.tiposDisponibles});

  factory FotosOptions.fromJson(Map<String, dynamic> json) {
    return FotosOptions(
      tiposDisponibles:
          (json['tipos_disponibles'] as List<dynamic>?)
              ?.map((e) => TipoFotoOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <TipoFotoOption>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipos_disponibles': tiposDisponibles.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() => 'FotosOptions(tiposDisponibles: $tiposDisponibles)';
}

/// Opción de tipo de foto disponible
class TipoFotoOption {
  final String value;
  final String label;

  const TipoFotoOption({required this.value, required this.label});

  factory TipoFotoOption.fromJson(Map<String, dynamic> json) {
    return TipoFotoOption(
      value: json['value'] as String,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'value': value, 'label': label};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TipoFotoOption &&
        other.value == value &&
        other.label == label;
  }

  @override
  int get hashCode => value.hashCode ^ label.hashCode;

  @override
  String toString() => 'TipoFotoOption(value: $value, label: $label)';
}

/// Modelo de respuesta al crear múltiples fotos
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
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: BulkCreateData.fromJson(
        json['data'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'data': data.toJson()};
  }

  @override
  String toString() =>
      'BulkCreateResponse(success: $success, message: $message, data: $data)';
}

/// Datos de respuesta de bulk create
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
      registroVinId: json['registro_vin_id'] as int? ?? 0,
      imagenesCreadas: json['imagenes_creadas'] as int? ?? 0,
      imagenes:
          (json['imagenes'] as List<dynamic>?)
              ?.map((e) => FotoPresentacion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <FotoPresentacion>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'registro_vin_id': registroVinId,
      'imagenes_creadas': imagenesCreadas,
      'imagenes': imagenes.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() =>
      'BulkCreateData(registroVinId: $registroVinId, imagenesCreadas: $imagenesCreadas, imagenes: $imagenes)';
}

/// Modelo de foto de presentación (response del backend)
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
      id: json['id'] as int,
      tipo: json['tipo'] as String,
      nDocumento: json['n_documento'] as String?,
      imagenUrl: json['imagen_url'] as String?,
      imagenThumbnailUrl: json['imagen_thumbnail_url'] as String?,
      createAt: json['create_at'] as String?,
      createBy: json['create_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      if (nDocumento != null) 'n_documento': nDocumento,
      if (imagenUrl != null) 'imagen_url': imagenUrl,
      if (imagenThumbnailUrl != null)
        'imagen_thumbnail_url': imagenThumbnailUrl,
      if (createAt != null) 'create_at': createAt,
      if (createBy != null) 'create_by': createBy,
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
    return other is FotoPresentacion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'FotoPresentacion(id: $id, tipo: $tipo, nDocumento: $nDocumento, hasImage: $hasImage)';
}
