import 'package:in_app_update/in_app_update.dart';
import 'dart:io' show Platform;

class UpdateService {
  static Future<void> checkForUpdate() async {
    if (!Platform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        // 🎯 IGUAL QUE EL EJEMPLO - DIRECTAMENTE INICIA FLEXIBLE UPDATE
        await _startUpdate();
      }
    } catch (error) {
      // Error silencioso - continúa normal
    }
  }

  static Future<void> _startUpdate() async {
    try {
      // 🔥 INICIA DESCARGA EN SEGUNDO PLANO (como el ejemplo)
      await InAppUpdate.startFlexibleUpdate();

      // 🔄 COMPLETA LA INSTALACIÓN AUTOMÁTICAMENTE
      await InAppUpdate.completeFlexibleUpdate();
    } catch (error) {
      // Error silencioso
    }
  }
}
