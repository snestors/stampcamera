// lib/models/autos/registro_vin_list_model.dart
import 'package:stampcamera/core/has_id.dart';

/// Item del listado de registros VIN individuales
/// (endpoint: /api/v1/autos/registro-vin/, ordenado del más reciente al más antiguo)
class RegistroVinListItem with HasId {
  @override
  final int id;
  final String vinNumero;
  final String marca;
  final String modelo;
  final String condicion;
  final String? zonaInspeccion;
  final String? contenedorLabel;
  final String? createAt; // Formato backend: "dd/MM/yyyy HH:mm" (hora Lima)
  final String? createBy;
  final String? nave;
  final String? fotoVinThumbnailUrl;

  const RegistroVinListItem({
    required this.id,
    required this.vinNumero,
    required this.marca,
    required this.modelo,
    required this.condicion,
    this.zonaInspeccion,
    this.contenedorLabel,
    this.createAt,
    this.createBy,
    this.nave,
    this.fotoVinThumbnailUrl,
  });

  factory RegistroVinListItem.fromJson(Map<String, dynamic> json) {
    return RegistroVinListItem(
      id: json['id'] ?? 0,
      vinNumero: json['vin_numero'] ?? '',
      marca: json['marca'] ?? '',
      modelo: json['modelo'] ?? '',
      condicion: json['condicion'] ?? '',
      zonaInspeccion: json['zona_inspeccion'],
      contenedorLabel: json['contenedor_label'],
      createAt: json['create_at'],
      createBy: json['create_by'],
      nave: json['nave'],
      fotoVinThumbnailUrl: json['foto_vin_thumbnail_url'],
    );
  }

  /// Fecha del registro (parte "dd/MM/yyyy" de createAt)
  String get fecha {
    final parts = (createAt ?? '').split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  /// Hora del registro con minutos (parte "HH:mm" de createAt)
  String get hora {
    final parts = (createAt ?? '').split(' ');
    return parts.length > 1 ? parts[1] : '';
  }
}

/// Usuario que ha realizado registros VIN (para el filtro por registrador)
class UsuarioRegistrador {
  final int id;
  final String nombre;

  const UsuarioRegistrador({required this.id, required this.nombre});
}
