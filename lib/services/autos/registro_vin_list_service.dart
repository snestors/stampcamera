// lib/services/autos/registro_vin_list_service.dart
import 'package:stampcamera/core/base_service_imp.dart';
import 'package:stampcamera/models/autos/registro_vin_list_model.dart';
import 'package:stampcamera/services/http_service.dart';

/// Servicio para el listado de registros VIN individuales.
/// El backend ordena por -id (más reciente primero) y soporta los filtros:
/// search, condicion, create_by, nave_descarga_id, embarque_id.
class RegistroVinListService extends BaseServiceImpl<RegistroVinListItem> {
  @override
  String get endpoint => '/api/v1/autos/registro-vin/';

  @override
  RegistroVinListItem Function(Map<String, dynamic>) get fromJson =>
      RegistroVinListItem.fromJson;

  /// Usuarios que han hecho registros, derivados del resumen de registros
  /// (participantes de los últimos días). No requiere endpoint adicional.
  Future<List<UsuarioRegistrador>> getUsuariosRegistradores() async {
    final response = await HttpService().dio.get(
      '${endpoint}resumen-registros/',
    );

    final results = response.data['results'] as List? ?? [];
    final usuarios = <int, UsuarioRegistrador>{};

    for (final dia in results) {
      final horas = dia['horas'] as List? ?? [];
      for (final hora in horas) {
        final participantes = hora['participantes'] as List? ?? [];
        for (final p in participantes) {
          final id = p['usuario_id'];
          if (id is int) {
            usuarios[id] = UsuarioRegistrador(
              id: id,
              nombre: (p['nombre'] as String?) ?? 'Usuario #$id',
            );
          }
        }
      }
    }

    final lista = usuarios.values.toList()
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return lista;
  }
}
