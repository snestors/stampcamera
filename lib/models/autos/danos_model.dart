// lib/models/autos/danos_model.dart
// 🔧 MODELOS ESPECÍFICOS PARA EL PROVIDER DE DAÑOS
// ✅ Modelos limpios para usar con DanosProvider
// ✅ Separados de detalle_registro_model.dart para mayor claridad

/// Modelo de opciones disponibles (response del endpoint /options)
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
          (json['tipos_dano'] as List<dynamic>?)
              ?.map((e) => TipoDanoOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <TipoDanoOption>[],
      areasDano:
          (json['areas_dano'] as List<dynamic>?)
              ?.map((e) => AreaDanoOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <AreaDanoOption>[],
      severidades:
          (json['severidades'] as List<dynamic>?)
              ?.map((e) => SeveridadOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <SeveridadOption>[],
      zonasDanos:
          (json['zonas_danos'] as List<dynamic>?)
              ?.map((e) => ZonaDanoOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <ZonaDanoOption>[],
      responsabilidades:
          (json['responsabilidades'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ResponsabilidadOption.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          <ResponsabilidadOption>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipos_dano': tiposDano.map((e) => e.toJson()).toList(),
      'areas_dano': areasDano.map((e) => e.toJson()).toList(),
      'severidades': severidades.map((e) => e.toJson()).toList(),
      'zonas_danos': zonasDanos.map((e) => e.toJson()).toList(),
      'responsabilidades': responsabilidades.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() =>
      'DanosOptions(tiposDano: ${tiposDano.length}, areasDano: ${areasDano.length}, severidades: ${severidades.length})';
}

/// Opción de tipo de daño disponible
class TipoDanoOption {
  final int value;
  final String label;

  const TipoDanoOption({required this.value, required this.label});

  factory TipoDanoOption.fromJson(Map<String, dynamic> json) {
    return TipoDanoOption(
      value: json['value'] as int,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'value': value, 'label': label};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TipoDanoOption &&
        other.value == value &&
        other.label == label;
  }

  @override
  int get hashCode => value.hashCode ^ label.hashCode;

  @override
  String toString() => 'TipoDanoOption(value: $value, label: $label)';
}

/// Opción de área de daño disponible
class AreaDanoOption {
  final int value;
  final String label;

  const AreaDanoOption({required this.value, required this.label});

  factory AreaDanoOption.fromJson(Map<String, dynamic> json) {
    return AreaDanoOption(
      value: json['value'] as int,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'value': value, 'label': label};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AreaDanoOption &&
        other.value == value &&
        other.label == label;
  }

  @override
  int get hashCode => value.hashCode ^ label.hashCode;

  @override
  String toString() => 'AreaDanoOption(value: $value, label: $label)';
}

/// Opción de severidad disponible
class SeveridadOption {
  final int value;
  final String label;

  const SeveridadOption({required this.value, required this.label});

  factory SeveridadOption.fromJson(Map<String, dynamic> json) {
    return SeveridadOption(
      value: json['value'] as int,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'value': value, 'label': label};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SeveridadOption &&
        other.value == value &&
        other.label == label;
  }

  @override
  int get hashCode => value.hashCode ^ label.hashCode;

  @override
  String toString() => 'SeveridadOption(value: $value, label: $label)';
}

/// Opción de zona de daño disponible
class ZonaDanoOption {
  final int value;
  final String label;

  const ZonaDanoOption({required this.value, required this.label});

  factory ZonaDanoOption.fromJson(Map<String, dynamic> json) {
    return ZonaDanoOption(
      value: json['value'] as int,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'value': value, 'label': label};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ZonaDanoOption &&
        other.value == value &&
        other.label == label;
  }

  @override
  int get hashCode => value.hashCode ^ label.hashCode;

  @override
  String toString() => 'ZonaDanoOption(value: $value, label: $label)';
}

/// Opción de responsabilidad disponible
class ResponsabilidadOption {
  final int value;
  final String label;

  const ResponsabilidadOption({required this.value, required this.label});

  factory ResponsabilidadOption.fromJson(Map<String, dynamic> json) {
    return ResponsabilidadOption(
      value: json['value'] as int,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'value': value, 'label': label};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResponsabilidadOption &&
        other.value == value &&
        other.label == label;
  }

  @override
  int get hashCode => value.hashCode ^ label.hashCode;

  @override
  String toString() => 'ResponsabilidadOption(value: $value, label: $label)';
}

/// Modelo básico de daño para el provider (simplified version)
class DanoBasico {
  final int id;
  final String? descripcion;
  final int tipoDano;
  final int areaDano;
  final int severidad;
  final List<int> zonas;
  final int? responsabilidad;
  final bool relevante;
  final List<String> imagePaths;
  final String? createAt;
  final String? createBy;

  const DanoBasico({
    required this.id,
    this.descripcion,
    required this.tipoDano,
    required this.areaDano,
    required this.severidad,
    required this.zonas,
    this.responsabilidad,
    required this.relevante,
    required this.imagePaths,
    this.createAt,
    this.createBy,
  });

  factory DanoBasico.fromJson(Map<String, dynamic> json) {
    return DanoBasico(
      id: json['id'] as int,
      descripcion: json['descripcion'] as String?,
      tipoDano: json['tipo_dano'] as int,
      areaDano: json['area_dano'] as int,
      severidad: json['severidad'] as int,
      zonas:
          (json['zonas'] as List<dynamic>?)?.map((e) => e as int).toList() ??
          [],
      responsabilidad: json['responsabilidad'] as int?,
      relevante: json['relevante'] as bool? ?? false,
      imagePaths:
          (json['image_paths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createAt: json['create_at'] as String?,
      createBy: json['create_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (descripcion != null) 'descripcion': descripcion,
      'tipo_dano': tipoDano,
      'area_dano': areaDano,
      'severidad': severidad,
      'zonas': zonas,
      if (responsabilidad != null) 'responsabilidad': responsabilidad,
      'relevante': relevante,
      'image_paths': imagePaths,
      if (createAt != null) 'create_at': createAt,
      if (createBy != null) 'create_by': createBy,
    };
  }

  /// Getter para verificar si tiene imágenes
  bool get hasImages => imagePaths.isNotEmpty;

  /// Getter para obtener número de imágenes
  int get imageCount => imagePaths.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DanoBasico && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DanoBasico(id: $id, tipoDano: $tipoDano, areaDano: $areaDano, hasImages: $hasImages)';
}
