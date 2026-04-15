import 'package:flutter/widgets.dart';
import 'package:in_app_update/in_app_update.dart';
import 'dart:io' show Platform;

/// Servicio de actualización obligatoria via Google Play.
/// Chequea al iniciar la app y cada vez que vuelve del background.
class UpdateService with WidgetsBindingObserver {
  static final UpdateService _instance = UpdateService._();
  factory UpdateService() => _instance;
  UpdateService._();

  bool _initialized = false;

  /// Inicializar: registra el observer de lifecycle
  void initialize() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    // Chequeo inicial
    checkForUpdate();
  }

  /// Se ejecuta cuando la app vuelve del background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkForUpdate();
    }
  }

  /// Chequea Play Store por update disponible → fuerza actualización inmediata
  static Future<void> checkForUpdate() async {
    if (!Platform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (_) {
      // Error silencioso — no bloquear si Play Store no responde
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _initialized = false;
  }
}
