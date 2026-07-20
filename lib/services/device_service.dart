import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:stampcamera/services/biometric_service.dart';
import 'package:stampcamera/services/http_service.dart';
import 'package:stampcamera/services/storage_health_service.dart'; // Importa appSecureStorage

/// Modelo para el estado del dispositivo
class DeviceStatus {
  final bool registered;
  final String? type; // 'personal' | 'shared'
  final String? deviceName;
  final DeviceUser? user;
  final String? error;

  DeviceStatus({
    required this.registered,
    this.type,
    this.deviceName,
    this.user,
    this.error,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      registered: json['registered'] ?? false,
      type: json['type'],
      deviceName: json['device_name'],
      user: json['user'] != null ? DeviceUser.fromJson(json['user']) : null,
      error: json['error'],
    );
  }

  factory DeviceStatus.notRegistered() {
    return DeviceStatus(registered: false);
  }

  factory DeviceStatus.error(String message) {
    return DeviceStatus(registered: false, error: message);
  }
}

class DeviceUser {
  final String? username;
  final String? firstName;
  final String? lastName;

  DeviceUser({this.username, this.firstName, this.lastName});

  factory DeviceUser.fromJson(Map<String, dynamic> json) {
    return DeviceUser(
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }

  String get fullName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    return parts.isNotEmpty ? parts.join(' ') : username ?? '';
  }
}

/// Servicio para manejo de dispositivos de confianza.
/// El registro de equipos (personal por OTP/aprobación, compartido) vive en
/// el flujo de login (auth/login/start/) — aquí solo queda la validación
/// del device_id almacenado y el storage local.
class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  final _http = HttpService();
  final _storage = appSecureStorage; // Usar instancia global compartida

  static const String _deviceIdKey = 'device_id';
  static const String _deviceTypeKey = 'device_type';
  static const String _deviceNameKey = 'device_name';
  static const String _deviceUsernameKey = 'device_username';

  /// Obtiene el device_id almacenado localmente
  Future<String?> getStoredDeviceId() async {
    try {
      return await _storage.read(key: _deviceIdKey);
    } on PlatformException catch (e) {
      // Solo PlatformException indica corrupcion real del storage
      debugPrint('❌ DeviceService: PlatformException leyendo device_id - $e');
      try {
        await storageHealthService.forceCleanStorage();
        debugPrint('🧹 DeviceService: Storage reparado');
      } catch (_) {}
      return null;
    } catch (e) {
      // Otros errores no requieren limpiar storage
      debugPrint('⚠️ DeviceService: Error leyendo device_id - $e');
      return null;
    }
  }

  /// Almacena el device_id localmente
  Future<void> storeDeviceId(String deviceId) async {
    await _storage.write(key: _deviceIdKey, value: deviceId);
  }

  /// Almacena información del dispositivo registrado
  Future<void> storeDeviceInfo({
    required String deviceId,
    required String type,
    String? deviceName,
    String? username,
  }) async {
    await _storage.write(key: _deviceIdKey, value: deviceId);
    await _storage.write(key: _deviceTypeKey, value: type);
    if (deviceName != null) {
      await _storage.write(key: _deviceNameKey, value: deviceName);
    }
    // Guardar username para equipos personales
    if (username != null && type == 'personal') {
      await _storage.write(key: _deviceUsernameKey, value: username);
    }
  }

  /// Obtiene el username del dispositivo (solo para equipos personales)
  Future<String?> getStoredUsername() async {
    try {
      return await _storage.read(key: _deviceUsernameKey);
    } catch (e) {
      debugPrint('❌ DeviceService: Error leyendo username - $e');
      return null;
    }
  }

  /// Obtiene el tipo de dispositivo almacenado
  Future<String?> getStoredDeviceType() async {
    try {
      return await _storage.read(key: _deviceTypeKey);
    } catch (e) {
      debugPrint('❌ DeviceService: Error leyendo device_type - $e');
      return null;
    }
  }

  /// Verifica si es un dispositivo personal
  Future<bool> isPersonalDevice() async {
    try {
      final type = await getStoredDeviceType();
      return type == 'personal';
    } catch (e) {
      return false;
    }
  }

  /// Limpia la información del dispositivo (incluyendo biométrico)
  Future<void> clearDeviceInfo() async {
    await _storage.delete(key: _deviceIdKey);
    await _storage.delete(key: _deviceTypeKey);
    await _storage.delete(key: _deviceNameKey);
    await _storage.delete(key: _deviceUsernameKey);
    // Limpiar biométrico al desvincular dispositivo
    await BiometricService().disableBiometric();
  }

  /// Verifica el estado del dispositivo en el servidor
  /// GET /api/v1/check-device/
  Future<DeviceStatus> checkDevice() async {
    final deviceId = await getStoredDeviceId();

    if (deviceId == null) {
      return DeviceStatus.notRegistered();
    }

    try {
      final response = await _http.dio.get(
        'api/v1/check-device/',
        options: Options(headers: {'X-Device-ID': deviceId}),
      );

      return DeviceStatus.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        // Device ID inválido o no enviado
        return DeviceStatus.notRegistered();
      }
      return DeviceStatus.error(_handleDioError(e));
    } catch (e) {
      return DeviceStatus.error('Error verificando dispositivo: $e');
    }
  }

  String _handleDioError(DioException e) {
    if (e.response?.data != null && e.response?.data is Map) {
      final data = e.response?.data as Map;
      if (data.containsKey('error')) {
        return data['error'].toString();
      }
      if (data.containsKey('detail')) {
        return data['detail'].toString();
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de conexión agotado';
      case DioExceptionType.connectionError:
        return 'Error de conexión. Verifica tu internet.';
      default:
        if (e.response?.statusCode == 404) {
          return 'Recurso no encontrado';
        }
        if (e.response?.statusCode == 400) {
          return 'Datos inválidos';
        }
        return 'Error de red: ${e.message}';
    }
  }
}
