import 'package:stampcamera/models/autos/registro_general_model.dart';

class RegistroVinOptions {
  final List<CondicionOption> condiciones;
  final List<ZonaInspeccionOption> zonasInspeccion;
  final List<BloqueOption> bloques;
  final Map<String, FieldPermission> fieldPermissions;
  final Map<String, dynamic> initialValues;
  final List<RegistroGeneral> vinsDisponibles; // ✅ Reutilizamos RegistroGeneral
  final List<ContenedorDisponible> contenedoresDisponibles;

  const RegistroVinOptions({
    required this.condiciones,
    required this.zonasInspeccion,
    required this.bloques,
    required this.fieldPermissions,
    required this.initialValues,
    required this.vinsDisponibles,
    required this.contenedoresDisponibles,
  });

  factory RegistroVinOptions.fromJson(Map<String, dynamic> json) {
    return RegistroVinOptions(
      condiciones:
          (json['condiciones'] as List?)
              ?.map((e) => CondicionOption.fromJson(e))
              .toList() ??
          [],
      zonasInspeccion:
          (json['zonas_inspeccion'] as List?)
              ?.map((e) => ZonaInspeccionOption.fromJson(e))
              .toList() ??
          [],
      bloques:
          (json['bloques'] as List?)
              ?.map((e) => BloqueOption.fromJson(e))
              .toList() ??
          [],
      fieldPermissions:
          (json['field_permissions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, FieldPermission.fromJson(value)),
          ) ??
          {},
      initialValues: json['initial_values'] ?? {},
      // ✅ Usamos RegistroGeneral.fromJson para vins_disponibles
      vinsDisponibles:
          (json['vins_disponibles'] as List?)
              ?.map((e) => RegistroGeneral.fromJson(e))
              .toList() ??
          [],
      contenedoresDisponibles:
          (json['contenedores_disponibles'] as List?)
              ?.map((e) => ContenedorDisponible.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class CondicionOption {
  final String value;
  final String label;

  const CondicionOption({required this.value, required this.label});

  factory CondicionOption.fromJson(Map<String, dynamic> json) {
    return CondicionOption(value: json['value'], label: json['label']);
  }
}

class ZonaInspeccionOption {
  final int value;
  final String label;

  const ZonaInspeccionOption({required this.value, required this.label});

  factory ZonaInspeccionOption.fromJson(Map<String, dynamic> json) {
    return ZonaInspeccionOption(value: json['value'], label: json['label']);
  }
}

class BloqueOption {
  final int value;
  final String label;

  const BloqueOption({required this.value, required this.label});

  factory BloqueOption.fromJson(Map<String, dynamic> json) {
    return BloqueOption(value: json['value'], label: json['label']);
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

// ✅ ACTUALIZADA: ContenedorDisponible con información de nave
class ContenedorDisponible {
  final int id;
  final String nContenedor;
  final String? naveDescarga; // ✅ AGREGAR campo de nave
  final int? naveDescargaId; // ✅ AGREGAR ID de nave

  const ContenedorDisponible({
    required this.id,
    required this.nContenedor,
    this.naveDescarga, // ✅ NUEVO
    this.naveDescargaId, // ✅ NUEVO
  });

  factory ContenedorDisponible.fromJson(Map<String, dynamic> json) {
    return ContenedorDisponible(
      id: json['id'],
      nContenedor: json['n_contenedor'],
      naveDescarga: json['nave_descarga'], // ✅ NUEVO
      naveDescargaId: json['nave_descarga_id'], // ✅ NUEVO
    );
  }

  // ✅ NUEVO: Getter para mostrar información completa
  String get displayText =>
      naveDescarga != null ? '$nContenedor - $naveDescarga' : nContenedor;
}
