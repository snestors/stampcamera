// ✅ Manejo específico de errores de red
import 'package:dio/dio.dart';

String parseError(dynamic error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Conexión lenta - Revisa tu internet y vuelve a intentar';
      case DioExceptionType.receiveTimeout:
        return 'El servidor tardó demasiado en responder';
      case DioExceptionType.sendTimeout:
        return 'Error enviando datos - Revisa tu conexión';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (status == 401) {
          return 'Sesión expirada - Vuelve a iniciar sesión';
        } else if (status == 403) {
          return 'No tienes permisos para ver estos registros';
        } else if (status == 404) {
          return 'Servicio no encontrado';
        } else if (status != null && status >= 500) {
          return 'Error del servidor - Intenta más tarde';
        }
        return 'Error del servidor (${status ?? 'desconocido'})';
      case DioExceptionType.cancel:
        return 'Operación cancelada';
      case DioExceptionType.connectionError:
        return 'Sin conexión a internet';
      case DioExceptionType.badCertificate:
        return 'Error de seguridad en la conexión';
      case DioExceptionType.unknown:
        return 'Error de conexión - Revisa tu internet';
    }
  }
  return 'Error inesperado: ${error.toString()}';
}
