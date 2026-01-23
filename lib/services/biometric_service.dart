import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Servicio para manejo de autenticación biométrica
/// Solo disponible para dispositivos personales
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricPasswordKey = 'biometric_password';

  /// Contraseña pendiente de configurar biométrico (en memoria, no persiste)
  String? _pendingPassword;

  /// Flag para evitar doble-prompt si el usuario canceló recientemente
  bool _recentlyDeclined = false;

  /// Guarda temporalmente la contraseña para configurar biométrico después del redirect
  void setPendingPassword(String password) {
    _pendingPassword = password;
  }

  /// Consume la contraseña pendiente (devuelve y limpia)
  String? consumePendingPassword() {
    final pwd = _pendingPassword;
    _pendingPassword = null;
    return pwd;
  }

  /// Verifica si el dispositivo tiene hardware biométrico disponible
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Verifica si hay biométricos enrollados (huella o face configurados)
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;

      final availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene los tipos de biométricos disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Autentica al usuario con biométrico
  /// Retorna true si la autenticación fue exitosa
  Future<bool> authenticate() async {
    try {
      final result = await _auth.authenticate(
        localizedReason: 'Verifica tu identidad para iniciar sesión',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (!result) {
        _recentlyDeclined = true;
      }
      return result;
    } catch (e) {
      _recentlyDeclined = true;
      return false;
    }
  }

  /// Verifica si el usuario canceló el biométrico recientemente
  bool get wasRecentlyDeclined => _recentlyDeclined;

  /// Limpia el flag de rechazo (para permitir retry manual)
  void clearDeclined() {
    _recentlyDeclined = false;
  }

  /// Verifica si el biométrico está habilitado para este dispositivo
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  /// Habilita el biométrico y almacena la contraseña encriptada
  Future<void> enableBiometric(String password) async {
    await _storage.write(key: _biometricEnabledKey, value: 'true');
    await _storage.write(key: _biometricPasswordKey, value: password);
  }

  /// Deshabilita el biométrico y elimina la contraseña almacenada
  Future<void> disableBiometric() async {
    await _storage.delete(key: _biometricEnabledKey);
    await _storage.delete(key: _biometricPasswordKey);
  }

  /// Obtiene la contraseña almacenada (solo después de autenticación biométrica)
  Future<String?> getStoredPassword() async {
    return await _storage.read(key: _biometricPasswordKey);
  }

  /// Verifica si tiene credenciales almacenadas para login biométrico
  Future<bool> hasStoredCredentials() async {
    final enabled = await isBiometricEnabled();
    if (!enabled) return false;

    final password = await _storage.read(key: _biometricPasswordKey);
    return password != null && password.isNotEmpty;
  }

  /// Flujo completo: verifica biométrico y retorna credenciales si éxito
  /// Retorna null si falla la autenticación
  Future<String?> authenticateAndGetPassword() async {
    final authenticated = await authenticate();
    if (!authenticated) return null;

    return await getStoredPassword();
  }
}
