import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Configuración ÚNICA de FlutterSecureStorage para toda la app.
/// IMPORTANTE: Todos los servicios DEBEN usar esta misma instancia
/// para evitar problemas de inconsistencia en Android.
const appSecureStorage = FlutterSecureStorage();

/// Servicio para verificar la salud del storage encriptado.
///
/// Problema: FlutterSecureStorage usa la firma de la app para encriptar datos.
/// Cuando se cambia entre versiones debug y release (o viceversa), los datos
/// encriptados se corrompen porque usan diferentes claves de firma.
///
/// Solucion: Solo limpiar storage cuando hay un error REAL de lectura
/// (PlatformException), no por verificaciones proactivas.
class StorageHealthService {
  static final StorageHealthService _instance = StorageHealthService._internal();
  factory StorageHealthService() => _instance;
  StorageHealthService._internal();

  // Usar la instancia global compartida
  final _storage = appSecureStorage;

  /// Verifica la salud del storage al iniciar la app.
  /// Solo limpia si hay un error REAL de lectura (PlatformException).
  /// Retorna true si el storage esta sano, false si tuvo que limpiarlo.
  Future<bool> checkAndRepairStorage() async {
    debugPrint('🔍 StorageHealth: Iniciando verificacion de storage...');

    try {
      // Intentar leer una clave que sabemos que deberia existir o no
      // Si hay corrupcion, esta lectura fallara con PlatformException
      final access = await _storage.read(key: 'access');
      final deviceId = await _storage.read(key: 'device_id');

      debugPrint('✅ StorageHealth: Storage verificado correctamente');
      debugPrint('   - access: ${access != null ? "presente" : "null"}');
      debugPrint('   - device_id: ${deviceId != null ? "presente ($deviceId)" : "null"}');
      return true;
    } on PlatformException catch (e) {
      // PlatformException = storage corrupto (cambio de firma debug/release)
      debugPrint('❌ StorageHealth: PlatformException detectada');
      debugPrint('   - code: ${e.code}');
      debugPrint('   - message: ${e.message}');
      debugPrint('   - details: ${e.details}');
      debugPrint('🧹 StorageHealth: Limpiando storage corrupto...');

      try {
        await _clearAllStorage();
        debugPrint('✅ StorageHealth: Storage reparado correctamente');
      } catch (clearError) {
        debugPrint('❌ StorageHealth: Error al limpiar storage - $clearError');
      }

      return false;
    } catch (e) {
      // Otros errores no implican corrupcion, no limpiar
      debugPrint('⚠️ StorageHealth: Error no critico (NO se limpia storage)');
      debugPrint('   - tipo: ${e.runtimeType}');
      debugPrint('   - mensaje: $e');
      return true;
    }
  }

  /// Limpia todo el storage de forma segura
  Future<void> _clearAllStorage() async {
    try {
      // Intentar deleteAll primero
      await _storage.deleteAll();
      debugPrint('🗑️ StorageHealth: deleteAll ejecutado');
    } catch (e) {
      debugPrint('⚠️ StorageHealth: deleteAll fallo, intentando borrado individual...');

      // Si deleteAll falla, intentar borrar claves conocidas individualmente
      final knownKeys = [
        'access',
        'refresh',
        'user_data',
        'device_id',
        'device_type',
        'device_name',
        'device_username',
        'biometric_password',
        'biometric_enabled',
      ];

      for (final key in knownKeys) {
        try {
          await _storage.delete(key: key);
        } catch (deleteError) {
          debugPrint('⚠️ StorageHealth: No se pudo borrar "$key"');
        }
      }
    }
  }

  /// Forzar limpieza del storage (para uso manual o testing)
  Future<void> forceCleanStorage() async {
    debugPrint('🧹 StorageHealth: Forzando limpieza de storage...');
    await _clearAllStorage();
    debugPrint('✅ StorageHealth: Storage limpiado forzosamente');
  }

  /// Verificar si hay tokens guardados (para saber si hay sesion)
  Future<bool> hasStoredSession() async {
    try {
      final access = await _storage.read(key: 'access');
      return access != null && access.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

/// Instancia global para facil acceso
final storageHealthService = StorageHealthService();
