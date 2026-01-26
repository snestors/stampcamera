import 'package:in_app_update/in_app_update.dart';
import 'dart:io' show Platform;

class UpdateService {
  static Future<void> checkForUpdate() async {
    if (!Platform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.immediateUpdateAllowed) {
        // Actualización obligatoria - bloquea la app hasta que actualice
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (error) {
      // Error silencioso - continúa normal
    }
  }
}
