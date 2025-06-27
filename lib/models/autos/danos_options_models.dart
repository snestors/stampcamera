// lib/models/autos/danos_options_models.dart

// ============================================================================
// MODELO PRINCIPAL DE OPCIONES DE DAÑOS
// ============================================================================

class DanosOptions {
  final List<TipoDanoOption> tiposDano;
  final List<AreaDanoOption> areasDano;
  final List<SeveridadOption> severidades;
  final List<ZonaDanoOption> zonasDanos;
  final List<ResponsabilidadOption> responsabilidades;
  final Map<String, FieldPermission> fieldPermissions;

  const DanosOptions({
    required this.tiposDano,
    required this.areasDano,
    required this.severidades,
    required this.zonasDanos,
    required this.responsabilidades,
    required this.fieldPermissions,
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
      fieldPermissions:
          (json['field_permissions'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, FieldPermission.fromJson(v)),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipos_dano': tiposDano.map((e) => e.toJson()).toList(),
      'areas_dano': areasDano.map((e) => e.toJson()).toList(),
      'severidades': severidades.map((e) => e.toJson()).toList(),
      'zonas_danos': zonasDanos.map((e) => e.toJson()).toList(),
      'responsabilidades': responsabilidades.map((e) => e.toJson()).toList(),
      'field_permissions': fieldPermissions.map(
        (k, v) => MapEntry(k, v.toJson()),
      ),
    };
  }
}

// ============================================================================
// MODELOS DE OPCIONES INDIVIDUALES
// ============================================================================

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
}

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
}

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
}

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
}

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
}

// ============================================================================
// MODELO DE PERMISOS DE CAMPO
// ============================================================================

class FieldPermission {
  final bool editable;
  final bool required;

  const FieldPermission({required this.editable, required this.required});

  factory FieldPermission.fromJson(Map<String, dynamic> json) {
    return FieldPermission(
      editable: json['editable'] as bool? ?? true,
      required: json['required'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'editable': editable, 'required': required};
  }
}
