import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/services/http_service.dart';
import 'package:stampcamera/services/login_flow_service.dart';
import 'package:stampcamera/utils/notification_route_mapper.dart';

/// Notificaciones push vía FCM (proyecto Firebase `fcm-django-bd051`).
///
/// Diseño (alineado con la web /app):
/// - El token se registra en `POST /save-fcm-token/` tras el login (JWT).
///   Se manda `previous_token` cuando el token rotó para que el backend
///   borre el Device viejo (FCM acepta envíos a tokens muertos sin error).
///   getToken() y onTokenRefresh disparan casi a la vez en el arranque:
///   single-flight + dedupe por sesión dejan UN solo POST por token.
/// - En background/terminada, el bloque `notification` del mensaje lo pinta
///   la bandeja del sistema — no hay código involucrado.
/// - En foreground NO se muestra nada: el WebSocket ws/app/ ya entrega las
///   notificaciones en vivo dentro de la app (FCM es el respaldo).
/// - Al tocar la push, `data.route` (path web relativo) se mapea a una ruta
///   de la app para navegar.
/// - En logout se hace `deleteToken()` client-side (igual que la web); el
///   backend elimina el Device cuando un envío falla.
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final _http = HttpService();

  /// Último token registrado con ÉXITO (persistente): viaja como
  /// `previous_token` cuando el token cambia.
  static const _lastTokenKey = 'fcm_last_registered_token';

  bool _registeredThisSession = false;
  String? _lastSentTokenThisSession;
  Future<void>? _inFlight;
  StreamSubscription<String>? _tokenRefreshSub;
  GoRouter? _router;

  /// true si Firebase.initializeApp() tuvo éxito (requiere
  /// google-services.json en Android / GoogleService-Info.plist en iOS)
  static bool firebaseAvailable = false;

  /// Inicializa Firebase. Llamar una vez desde main() antes de runApp.
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      firebaseAvailable = true;
      debugPrint('🔔 Firebase inicializado');
    } catch (e) {
      // Sin config de Firebase (p.ej. iOS sin plist) la app funciona
      // normal, solo sin push
      firebaseAvailable = false;
      debugPrint('⚠️ Firebase no disponible: $e');
    }
  }

  /// Configura la navegación al tocar una push (app en background o
  /// terminada). Llamar una vez desde main() después de crear el router.
  Future<void> setupInteractedMessages(GoRouter router) async {
    if (!firebaseAvailable) return;
    _router = router;

    // App terminada → abierta desde la notificación
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    // App en background → traída al frente desde la notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
  }

  /// Pide permiso, obtiene el token y lo registra en el backend.
  /// Idempotente por sesión de app; se llama tras cada login/check-auth.
  Future<void> registerAfterLogin() async {
    if (!firebaseAvailable || _registeredThisSession) return;

    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('🔕 Permiso de notificaciones denegado');
        return;
      }

      final token = await messaging.getToken();
      if (token == null) return;

      await _sendTokenToBackend(token);
      _registeredThisSession = true;

      _tokenRefreshSub ??= messaging.onTokenRefresh.listen((newToken) {
        _sendTokenToBackend(newToken).catchError((Object e) {
          debugPrint('⚠️ Error re-registrando token FCM rotado: $e');
        });
      });

      debugPrint('🔔 Token FCM registrado');
    } catch (e) {
      debugPrint('⚠️ Error registrando token FCM: $e');
    }
  }

  /// Borra el token en FCM (client-side, igual que la web) para que el
  /// usuario saliente no siga recibiendo push en un teléfono compartido.
  /// El Device viejo del servidor se limpia en el siguiente registro vía
  /// `previous_token` (el token persistido NO se borra aquí a propósito).
  Future<void> onLogout() async {
    _registeredThisSession = false;
    _lastSentTokenThisSession = null;
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    if (!firebaseAvailable) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
      debugPrint('🔕 Token FCM eliminado (logout)');
    } catch (e) {
      debugPrint('⚠️ Error eliminando token FCM: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    // Serializar POSTs concurrentes (getToken + onTokenRefresh del arranque)
    while (_inFlight != null) {
      try {
        await _inFlight;
      } catch (_) {
        // El error lo maneja quien originó ese POST
      }
    }
    // Ya registrado esta sesión con este mismo token: nada que hacer
    if (token == _lastSentTokenThisSession) return;

    final future = _postToken(token);
    _inFlight = future;
    try {
      await future;
    } finally {
      _inFlight = null;
    }
  }

  Future<void> _postToken(String token) async {
    final previousToken = await _http.storage.read(key: _lastTokenKey);
    final deviceName = await LoginFlowService().deviceName();

    await _http.dio.post(
      'save-fcm-token/',
      data: {
        'token': token,
        'user_agent': deviceName,
        'battery_level': 'unknown',
        'mobile': true,
        // Rotación: el backend borra el Device del token anterior
        if (previousToken != null &&
            previousToken.isNotEmpty &&
            previousToken != token)
          'previous_token': previousToken,
      },
    );

    _lastSentTokenThisSession = token;
    await _http.storage.write(key: _lastTokenKey, value: token);
  }

  void _handleMessageTap(RemoteMessage message) {
    final route = message.data['route'] as String?;
    final appRoute = mapWebRouteToApp(route);
    debugPrint('🔔 Push tocada: route=$route → $appRoute');
    if (appRoute != null) {
      _router?.go(appRoute);
    }
  }
}
