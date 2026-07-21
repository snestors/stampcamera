import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

/// Servicio de actualización obligatoria.
/// Chequea al iniciar la app y cada vez que vuelve del background.
///
/// - Android: API In-App Updates de Google Play (update inmediato forzado).
/// - iOS: consulta la versión publicada en App Store (iTunes lookup) y si la
///   instalada es menor muestra un diálogo bloqueante que abre App Store
///   (Apple no permite auto-actualizar desde dentro de la app).
class UpdateService with WidgetsBindingObserver {
  static final UpdateService _instance = UpdateService._();
  factory UpdateService() => _instance;
  UpdateService._();

  static const _bundleId = 'com.nestorfar.stampcamera';
  static const _appStoreId = '6791653349';
  // La app se distribuye en el store de Perú
  static const _lookupUrl =
      'https://itunes.apple.com/lookup?bundleId=$_bundleId&country=pe';
  static const _appStoreUrl =
      'https://apps.apple.com/app/id$_appStoreId';

  bool _initialized = false;
  bool _dialogVisible = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Inicializar: registra el observer de lifecycle.
  /// [navigatorKey] (requerido para iOS) da el context del diálogo bloqueante.
  void initialize({GlobalKey<NavigatorState>? navigatorKey}) {
    _navigatorKey = navigatorKey;
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

  /// Chequea el store por update disponible → fuerza actualización
  static Future<void> checkForUpdate() async {
    if (Platform.isAndroid) {
      await _checkAndroid();
    } else if (Platform.isIOS) {
      await _instance._checkIOS();
    }
  }

  static Future<void> _checkAndroid() async {
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

  Future<void> _checkIOS() async {
    if (_dialogVisible) return;
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      final response = await Dio().get<Map<String, dynamic>>(
        _lookupUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      final results = response.data?['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return;

      final storeVersion = results.first['version'] as String?;
      if (storeVersion == null) return;

      if (_isNewer(storeVersion, packageInfo.version)) {
        _showBlockingDialog(storeVersion);
      }
    } catch (_) {
      // Error silencioso — no bloquear si iTunes no responde
    }
  }

  /// true si [store] es estrictamente mayor que [installed] (semver simple)
  static bool _isNewer(String store, String installed) {
    final s = store.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final i = installed.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    for (var n = 0; n < 3; n++) {
      final sv = n < s.length ? s[n] : 0;
      final iv = n < i.length ? i[n] : 0;
      if (sv != iv) return sv > iv;
    }
    return false;
  }

  void _showBlockingDialog(String storeVersion) {
    final context = _navigatorKey?.currentContext;
    if (context == null || _dialogVisible) return;
    _dialogVisible = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Actualización requerida'),
          content: Text(
            'Hay una nueva versión disponible ($storeVersion). '
            'Para continuar usando la aplicación debes actualizarla.',
          ),
          actions: [
            FilledButton.icon(
              icon: const Icon(Icons.system_update_alt),
              label: const Text('Actualizar en App Store'),
              onPressed: () {
                launchUrl(
                  Uri.parse(_appStoreUrl),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
          ],
        ),
      ),
    ).whenComplete(() => _dialogVisible = false);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _initialized = false;
  }
}
