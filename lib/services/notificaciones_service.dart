import 'package:stampcamera/models/notificacion_model.dart';
import 'package:stampcamera/services/http_service.dart';

/// Consume los endpoints de la bandeja de notificaciones (espejo de la web).
///
/// OJO: viven en `/notificaciones/` (fuera de /api/v1/) y "marcar como
/// leída" ELIMINA la notificación en el servidor — la bandeja es efímera
/// por diseño (Celery además borra todo lo de más de 2 días).
class NotificacionesService {
  final _http = HttpService();

  Future<List<NotificacionModel>> fetch() async {
    final res = await _http.dio.get('notificaciones/');
    final data = res.data;
    final list = (data is Map ? data['notificaciones'] as List? : null) ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(NotificacionModel.fromApiJson)
        .toList();
  }

  Future<void> markAsRead(int id) async {
    await _http.dio.post('notificaciones/mark-as-read/$id/');
  }

  Future<void> markAllAsRead() async {
    await _http.dio.post('notificaciones/mark-all-as-read/');
  }
}
