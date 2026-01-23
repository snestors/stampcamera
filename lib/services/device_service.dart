import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'biometric_service.dart';
import 'http_service.dart';

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

/// Resultado de solicitar código
class RequestCodeResult {
  final bool success;
  final String? method; // 'email' | 'admin'
  final String? maskedEmail;
  final String? deviceId;
  final String? message;
  final String? error;

  RequestCodeResult({
    required this.success,
    this.method,
    this.maskedEmail,
    this.deviceId,
    this.message,
    this.error,
  });

  factory RequestCodeResult.fromJson(Map<String, dynamic> json) {
    return RequestCodeResult(
      success: json['success'] ?? false,
      method: json['method'],
      maskedEmail: json['masked_email'],
      deviceId: json['device_id'],
      message: json['message'],
      error: json['error'],
    );
  }

  factory RequestCodeResult.error(String message) {
    return RequestCodeResult(success: false, error: message);
  }
}

/// Resultado de registrar dispositivo
class RegisterDeviceResult {
  final bool success;
  final String? type; // 'personal' | 'shared'
  final String? deviceName;
  final DeviceUser? user;
  final String? message;
  final String? error;

  RegisterDeviceResult({
    required this.success,
    this.type,
    this.deviceName,
    this.user,
    this.message,
    this.error,
  });

  factory RegisterDeviceResult.fromJson(Map<String, dynamic> json) {
    return RegisterDeviceResult(
      success: json['success'] ?? false,
      type: json['type'],
      deviceName: json['device_name'],
      user: json['user'] != null ? DeviceUser.fromJson(json['user']) : null,
      message: json['message'],
      error: json['error'],
    );
  }

  factory RegisterDeviceResult.error(String message) {
    return RegisterDeviceResult(success: false, error: message);
  }
}

/// Servicio para manejo de dispositivos de confianza
class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  final _http = HttpService();
  final _storage = const FlutterSecureStorage();

  static const String _deviceIdKey = 'device_id';
  static const String _deviceTypeKey = 'device_type';
  static const String _deviceNameKey = 'device_name';
  static const String _deviceUsernameKey = 'device_username';

  /// Obtiene el device_id almacenado localmente
  Future<String?> getStoredDeviceId() async {
    return await _storage.read(key: _deviceIdKey);
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
    return await _storage.read(key: _deviceUsernameKey);
  }

  /// Obtiene el tipo de dispositivo almacenado
  Future<String?> getStoredDeviceType() async {
    return await _storage.read(key: _deviceTypeKey);
  }

  /// Verifica si es un dispositivo personal
  Future<bool> isPersonalDevice() async {
    final type = await getStoredDeviceType();
    return type == 'personal';
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

  /// Solicita código de verificación
  /// POST /api/v1/device/request-code/
  Future<RequestCodeResult> requestCode({
    required String username,
    String? deviceName,
  }) async {
    try {
      final response = await _http.dio.post(
        'api/v1/device/request-code/',
        data: {
          'username': username,
          if (deviceName != null) 'device_name': deviceName,
        },
      );

      // Validar que la respuesta sea un Map
      if (response.data is! Map<String, dynamic>) {
        return RequestCodeResult.error('Respuesta inválida del servidor');
      }

      final result = RequestCodeResult.fromJson(response.data);

      // Validar que si es exitoso, tenga método
      if (result.success && result.method == null) {
        return RequestCodeResult.error('El servidor no indicó el método de verificación');
      }

      // Si es exitoso, almacenar el device_id temporalmente
      if (result.success && result.deviceId != null) {
        await storeDeviceId(result.deviceId!);
      }

      return result;
    } on DioException catch (e) {
      return RequestCodeResult.error(_handleDioError(e));
    } catch (e) {
      return RequestCodeResult.error('Error solicitando código: $e');
    }
  }

  /// Registra dispositivo con código o token
  /// POST /api/v1/device/register/
  Future<RegisterDeviceResult> registerDevice({
    required String deviceId,
    String? code,
    String? token,
    String? deviceName,
  }) async {
    if (code == null && token == null) {
      return RegisterDeviceResult.error('Se requiere código o token');
    }

    try {
      final response = await _http.dio.post(
        'api/v1/device/register/',
        data: {
          'device_id': deviceId,
          if (code != null) 'code': code,
          if (token != null) 'token': token,
          if (deviceName != null) 'device_name': deviceName,
        },
      );

      final result = RegisterDeviceResult.fromJson(response.data);

      // Si es exitoso, almacenar información del dispositivo
      if (result.success) {
        await storeDeviceInfo(
          deviceId: deviceId,
          type: result.type ?? 'personal',
          deviceName: result.deviceName,
          username: result.user?.username,
        );
      }

      return result;
    } on DioException catch (e) {
      return RegisterDeviceResult.error(_handleDioError(e));
    } catch (e) {
      return RegisterDeviceResult.error('Error registrando dispositivo: $e');
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
