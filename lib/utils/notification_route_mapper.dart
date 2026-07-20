/// Mapea el path web de una notificación (`notificacion.url`) a una ruta
/// de la app. Compartido por el push FCM (background) y el centro de
/// notificaciones in-app (WS). Si no hay equivalente, retorna null y el
/// caller no navega.
String? mapWebRouteToApp(String? route) {
  if (route == null || route.isEmpty) return null;
  if (route.contains('casos')) return '/casos';
  if (route.contains('autos')) return '/autos';
  if (route.contains('graneles')) return '/graneles';
  if (route.contains('asistencia')) return '/asistencia';
  if (route.contains('equipos') || route.contains('device')) {
    // La pantalla valida internamente que sea superusuario
    return '/admin/device-requests';
  }
  return null;
}
