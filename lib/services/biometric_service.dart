// lib/services/biometric_service.dart
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Verifica si el dispositivo soporta biometría
  Future<bool> get isDeviceSupported async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      debugPrint('Error verificando soporte del dispositivo: $e');
      return false;
    }
  }

  /// Verifica si hay biometría disponible (configurada)
  Future<bool> get isBiometricAvailable async {
    try {
      final isSupported = await isDeviceSupported;
      if (!isSupported) return false;

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      debugPrint('Error verificando biometría disponible: $e');
      return false;
    }
  }

  /// Obtiene los tipos de biometría disponibles
  Future<List<BiometricType>> get availableBiometrics async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error obteniendo biometría disponible: $e');
      return [];
    }
  }

  /// Verifica si hay alguna biometría configurada
  Future<bool> get hasEnrolledBiometrics async {
    try {
      final biometrics = await availableBiometrics;
      return biometrics.isNotEmpty;
    } catch (e) {
      debugPrint('Error verificando biometría configurada: $e');
      return false;
    }
  }

  /// Obtiene el texto descriptivo según la biometría disponible
  Future<String> get biometricTypeText async {
    try {
      final biometrics = await availableBiometrics;

      if (biometrics.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        return 'Huella dactilar';
      } else if (biometrics.contains(BiometricType.iris)) {
        return 'Iris';
      } else if (biometrics.contains(BiometricType.strong)) {
        return 'Autenticación biométrica';
      } else if (biometrics.contains(BiometricType.weak)) {
        return 'Patrón o PIN';
      } else {
        return 'Autenticación biométrica';
      }
    } catch (e) {
      return 'Autenticación biométrica';
    }
  }

  /// Obtiene el ícono según la biometría disponible
  Future<String> get biometricIcon async {
    try {
      final biometrics = await availableBiometrics;

      if (biometrics.contains(BiometricType.face)) {
        return '🔒'; // O Icons.face para Material
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        return '👆'; // O Icons.fingerprint para Material
      } else if (biometrics.contains(BiometricType.iris)) {
        return '👁️'; // O Icons.remove_red_eye para Material
      } else {
        return '🔐'; // O Icons.security para Material
      }
    } catch (e) {
      return '🔐';
    }
  }

  /// Realiza la autenticación biométrica
  Future<BiometricAuthResult> authenticate({
    String localizedReason = 'Confirma tu identidad para continuar',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
    bool sensitiveTransaction = true,
  }) async {
    try {
      // Verificar disponibilidad
      final isAvailable = await isBiometricAvailable;
      if (!isAvailable) {
        return BiometricAuthResult.notAvailable;
      }

      // Autenticar con la nueva API
      final result = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          sensitiveTransaction: sensitiveTransaction,
          biometricOnly: true,
        ),
      );

      return result ? BiometricAuthResult.success : BiometricAuthResult.failure;
    } catch (e) {
      debugPrint('Error en autenticación biométrica: $e');

      // Manejar errores específicos
      if (e.toString().contains('UserCancel')) {
        return BiometricAuthResult.cancelled;
      } else if (e.toString().contains('NotEnrolled')) {
        return BiometricAuthResult.notEnrolled;
      } else if (e.toString().contains('NotAvailable')) {
        return BiometricAuthResult.notAvailable;
      } else {
        return BiometricAuthResult.error;
      }
    }
  }

  /// Método de conveniencia para verificar y autenticar
  Future<BiometricAuthResult> authenticateIfAvailable({
    String? customReason,
  }) async {
    final isAvailable = await isBiometricAvailable;
    if (!isAvailable) {
      return BiometricAuthResult.notAvailable;
    }

    final biometricText = await biometricTypeText;
    final reason = customReason ?? 'Usa tu $biometricText para acceder';

    return authenticate(localizedReason: reason);
  }

  /// Detener la autenticación (útil para cancelar desde código)
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      debugPrint('Error deteniendo autenticación: $e');
    }
  }
}

/// Enum para los resultados de autenticación biométrica
enum BiometricAuthResult {
  success, // Autenticación exitosa
  failure, // Falló la autenticación (huella incorrecta, etc.)
  cancelled, // Usuario canceló
  notAvailable, // No hay biometría disponible
  notEnrolled, // No hay biometría configurada
  error, // Error del sistema
}

/// Extension para obtener mensajes user-friendly
extension BiometricAuthResultExtension on BiometricAuthResult {
  String get message {
    switch (this) {
      case BiometricAuthResult.success:
        return 'Autenticación exitosa';
      case BiometricAuthResult.failure:
        return 'Autenticación fallida. Intenta de nuevo';
      case BiometricAuthResult.cancelled:
        return 'Autenticación cancelada';
      case BiometricAuthResult.notAvailable:
        return 'Autenticación biométrica no disponible';
      case BiometricAuthResult.notEnrolled:
        return 'No hay biometría configurada en el dispositivo';
      case BiometricAuthResult.error:
        return 'Error en la autenticación biométrica';
    }
  }

  bool get isSuccess => this == BiometricAuthResult.success;
}
