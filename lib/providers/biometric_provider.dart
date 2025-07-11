import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stampcamera/models/auth_state.dart';
import '../services/biometric_service.dart';
import 'auth_provider.dart';

class BiometricState {
  final bool isAvailable;
  final bool isEnabled;
  final String biometricType;
  final bool isLoading;
  final String? error;

  const BiometricState({
    this.isAvailable = false,
    this.isEnabled = false,
    this.biometricType = '',
    this.isLoading = false,
    this.error,
  });

  BiometricState copyWith({
    bool? isAvailable,
    bool? isEnabled,
    String? biometricType,
    bool? isLoading,
    String? error,
  }) {
    return BiometricState(
      isAvailable: isAvailable ?? this.isAvailable,
      isEnabled: isEnabled ?? this.isEnabled,
      biometricType: biometricType ?? this.biometricType,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final biometricProvider =
    StateNotifierProvider<BiometricNotifier, BiometricState>(
      (ref) => BiometricNotifier(ref),
    );

class BiometricNotifier extends StateNotifier<BiometricState> {
  BiometricNotifier(this._ref) : super(const BiometricState()) {
    _initialize();
  }

  final Ref _ref;
  final _biometricService = BiometricService();
  final _storage = const FlutterSecureStorage();

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricCredentialsKey = 'biometric_credentials';

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      final isAvailable = await _biometricService.isBiometricAvailable;
      final biometricType = await _biometricService.biometricTypeText;
      final isEnabled = await _getBiometricEnabledFromStorage();

      state = state.copyWith(
        isAvailable: isAvailable,
        isEnabled: isEnabled && isAvailable,
        biometricType: biometricType,
        isLoading: false,
        error: null,
      );

      print('🔒 BiometricProvider inicializado:');
      print('   isAvailable: $isAvailable');
      print('   isEnabled: ${isEnabled && isAvailable}');
      print('   biometricType: $biometricType');
    } catch (e) {
      print('❌ Error inicializando BiometricProvider: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error verificando biometría: $e',
      );
    }
  }

  Future<bool> setupBiometric(String username, String password) async {
    if (!state.isAvailable) {
      print('❌ BiometricProvider: Biometría no disponible');
      return false;
    }

    state = state.copyWith(isLoading: true);

    try {
      print('🔒 BiometricProvider: Habilitando biometría para: $username');

      final authResult = await _biometricService.authenticate(
        localizedReason:
            'Confirma tu ${state.biometricType} para habilitar el acceso rápido',
      );

      if (authResult.isSuccess) {
        print('✅ BiometricProvider: Autenticación exitosa, guardando...');

        await _saveBiometricCredentials(username, password);
        await _setBiometricEnabledInStorage(true);

        // ✅ Actualizar estado inmediatamente después de guardar
        final hasCredentials = await _hasCredentialsStored();

        state = state.copyWith(
          isEnabled: true && hasCredentials, // Asegurar que ambos están true
          isLoading: false,
          error: null,
        );

        print('✅ BiometricProvider: Biometría habilitada exitosamente');
        print('✅ BiometricProvider: Estado final isEnabled=${state.isEnabled}');
        return true;
      } else {
        print(
          '❌ BiometricProvider: Falló autenticación: ${authResult.message}',
        );
        state = state.copyWith(isLoading: false, error: authResult.message);
        return false;
      }
    } catch (e) {
      print('❌ BiometricProvider: Error en setupBiometric: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error configurando biometría: $e',
      );
      return false;
    }
  }

  Future<bool> disableBiometric() async {
    state = state.copyWith(isLoading: true);

    try {
      print('🔒 BiometricProvider: Deshabilitando biometría...');

      await _clearBiometricCredentials();
      await _setBiometricEnabledInStorage(false);

      state = state.copyWith(isEnabled: false, isLoading: false, error: null);
      print('✅ BiometricProvider: Biometría deshabilitada');
      return true;
    } catch (e) {
      print('❌ BiometricProvider: Error deshabilitando biometría: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error deshabilitando biometría: $e',
      );
      return false;
    }
  }

  Future<bool> authenticateAndLogin() async {
    if (!state.isEnabled || !state.isAvailable) {
      print('❌ BiometricProvider: Biometría no habilitada o no disponible');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🔒 BiometricProvider: Iniciando autenticación biométrica...');

      final authResult = await _biometricService.authenticate(
        localizedReason: 'Usa tu ${state.biometricType} para iniciar sesión',
      );

      if (authResult.isSuccess) {
        print('✅ BiometricProvider: Autenticación biométrica exitosa');

        final credentials = await _getBiometricCredentials();

        if (credentials != null) {
          print(
            '✅ BiometricProvider: Credenciales obtenidas, haciendo login...',
          );

          try {
            // Intentar login con credenciales guardadas (marcado como biométrico)
            await _ref
                .read(authProvider.notifier)
                .login(credentials['username']!, credentials['password']!, isBiometricLogin: true);

            // Verificar si el login fue exitoso
            final authState = _ref.read(authProvider);
            if (authState.hasError ||
                authState.value?.status == AuthStatus.loggedOut ||
                authState.value?.errorMessage != null) {
              
              final errorMessage = authState.value?.errorMessage ?? 'Error en login';
              
              // ⚠️ NO limpiar biometría automáticamente
              // Mantener biometría para limpieza manual desde configuración
              print('⚠️ BiometricProvider: Error en login, manteniendo biometría: $errorMessage');
              
              state = state.copyWith(
                isLoading: false,
                error: errorMessage,
              );
              return false;
            }

            state = state.copyWith(isLoading: false, error: null);
            print('✅ BiometricProvider: Login biométrico exitoso');
            return true;
          } catch (loginError) {
            print('❌ BiometricProvider: Error en login: $loginError');

            final errorString = loginError.toString();
            
            // ⚠️ NO limpiar biometría automáticamente por NINGÚN error
            // Solo permitir limpieza manual desde configuración
            print('⚠️ BiometricProvider: Error en login, manteniendo biometría: $errorString');
            
            state = state.copyWith(
              isLoading: false,
              error: 'Error en login. Si persiste, limpia manualmente la biometría desde configuración.',
            );
            return false;
          }
        } else {
          print('❌ BiometricProvider: No se encontraron credenciales');
          state = state.copyWith(
            isLoading: false,
            error: 'No se encontraron credenciales guardadas',
          );
          return false;
        }
      } else {
        print(
          '❌ BiometricProvider: Falló autenticación: ${authResult.message}',
        );
        state = state.copyWith(isLoading: false, error: authResult.message);
        return false;
      }
    } catch (e) {
      print('❌ BiometricProvider: Error en authenticateAndLogin: $e');

      // ⚠️ NO limpiar biometría automáticamente por error general
      // Solo permitir limpieza manual desde configuración
      print('⚠️ BiometricProvider: Error general, manteniendo biometría: $e');

      state = state.copyWith(
        isLoading: false,
        error: 'Error en la autenticación biométrica. Limpia manualmente desde configuración si es necesario.',
      );
      return false;
    }
  }

  Future<bool> hasStoredCredentials() async {
    return await _hasCredentialsStored();
  }

  /// Método privado para verificar credenciales
  Future<bool> _hasCredentialsStored() async {
    try {
      final credentials = await _storage.read(key: _biometricCredentialsKey);
      return credentials != null && credentials.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> refresh() async {
    await _initialize();
  }

  Future<void> clearAll() async {
    try {
      await _clearBiometricCredentials();
      await _setBiometricEnabledInStorage(false);

      state = state.copyWith(isEnabled: false, error: null);

      print('🗑️ BiometricProvider: Todo limpiado');
    } catch (e) {
      print('❌ BiometricProvider: Error limpiando todo: $e');
    }
  }

  // Métodos privados para storage
  Future<bool> _getBiometricEnabledFromStorage() async {
    try {
      final value = await _storage.read(key: _biometricEnabledKey);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  Future<void> _setBiometricEnabledInStorage(bool enabled) async {
    try {
      await _storage.write(
        key: _biometricEnabledKey,
        value: enabled.toString(),
      );
      print('🔧 BiometricProvider: Estado guardado: $enabled');
    } catch (e) {
      print('❌ BiometricProvider: Error guardando estado: $e');
    }
  }

  Future<void> _saveBiometricCredentials(
    String username,
    String password,
  ) async {
    try {
      final credentials = '$username:$password';
      await _storage.write(key: _biometricCredentialsKey, value: credentials);
      print('🔑 BiometricProvider: Credenciales guardadas para: $username');

      // Verificar inmediatamente que se guardaron
      final saved = await _storage.read(key: _biometricCredentialsKey);
      if (saved != null) {
        print(
          '✅ BiometricProvider: Verificación exitosa - credenciales en storage',
        );
      } else {
        print('❌ BiometricProvider: ERROR - credenciales NO se guardaron!');
        throw Exception('No se pudieron verificar las credenciales guardadas');
      }
    } catch (e) {
      print('❌ BiometricProvider: Error guardando credenciales: $e');
      throw Exception('No se pudieron guardar las credenciales biométricas');
    }
  }

  Future<Map<String, String>?> _getBiometricCredentials() async {
    try {
      print('🔒 BiometricProvider: Buscando credenciales biométricas...');
      print('🔒 BiometricProvider: Clave usada: $_biometricCredentialsKey');

      // Verificar todas las claves en storage para debug
      final allKeys = await _storage.readAll();
      print(
        '🔒 BiometricProvider: Todas las claves en storage: ${allKeys.keys.toList()}',
      );

      final credentials = await _storage.read(key: _biometricCredentialsKey);
      print('🔒 BiometricProvider: Valor obtenido: ${credentials ?? "NULL"}');

      if (credentials == null || credentials.isEmpty) {
        print('❌ BiometricProvider: No hay credenciales biométricas');
        return null;
      }

      final parts = credentials.split(':');
      if (parts.length != 2) {
        print('❌ BiometricProvider: Formato inválido: $credentials');
        return null;
      }

      print('✅ BiometricProvider: Credenciales encontradas para: ${parts[0]}');
      return {'username': parts[0], 'password': parts[1]};
    } catch (e) {
      print('❌ BiometricProvider: Error obteniendo credenciales: $e');
      return null;
    }
  }

  Future<void> _clearBiometricCredentials() async {
    try {
      await _storage.delete(key: _biometricCredentialsKey);
      print('🗑️ BiometricProvider: Credenciales biométricas limpiadas');
    } catch (e) {
      print('❌ BiometricProvider: Error limpiando credenciales: $e');
    }
  }
}
