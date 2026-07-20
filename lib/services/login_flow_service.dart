import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:stampcamera/models/login_flow_model.dart';
import 'package:stampcamera/services/http_service.dart';

/// Cliente del flujo de login con autorización de equipos.
///
/// Máquina de estados del backend (POST auth/login/start/):
///   authenticated → tokens directos (equipo ya de confianza)
///   pending_otp   → código de 6 dígitos al correo → verify-otp/
///   pending_admin → user_code visible → polling a device-approval/status/
///
/// El `flow_secret` conecta los pasos y viaja en el body JSON.
/// El `device_id` lo genera el servidor (64 hex) y el cliente debe adoptarlo;
/// el header X-Device-ID lo agrega el interceptor de HttpService si ya existe.
class LoginFlowService {
  static final LoginFlowService _instance = LoginFlowService._internal();
  factory LoginFlowService() => _instance;
  LoginFlowService._internal();

  final _http = HttpService();

  String? _cachedDeviceName;

  /// Nombre legible del equipo para que el admin reconozca la solicitud
  Future<String> deviceName() async {
    if (_cachedDeviceName != null) return _cachedDeviceName!;
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        _cachedDeviceName = '${info.manufacturer} ${info.model}'.trim();
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        _cachedDeviceName = '${info.model} (${info.utsname.machine})';
      } else {
        _cachedDeviceName = Platform.operatingSystem;
      }
    } catch (e) {
      debugPrint('⚠️ LoginFlowService: error obteniendo device name - $e');
      _cachedDeviceName = Platform.isIOS ? 'iPhone' : 'Android';
    }
    return _cachedDeviceName!;
  }

  /// POST /api/v1/auth/login/start/
  Future<LoginFlowResult> startLogin({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _http.dio.post(
        'api/v1/auth/login/start/',
        data: {
          'username': username,
          'password': password,
          'client_type': 'api',
          'device_name': await deviceName(),
        },
      );
      return _parseResult(response);
    } on DioException catch (e) {
      switch (e.response?.statusCode) {
        case 401:
          return LoginFlowResult.error('Usuario o contraseña incorrectos');
        case 400:
          return LoginFlowResult.error(
            _detail(e) ?? 'No se pudo iniciar el proceso de autenticación',
          );
        case 429:
          return LoginFlowResult.error(
            'Demasiados intentos de login. Intenta más tarde.',
          );
        default:
          return _mapDioError(e);
      }
    } catch (e) {
      return LoginFlowResult.error('Error inesperado: $e');
    }
  }

  /// POST /api/v1/auth/login/verify-otp/
  Future<LoginFlowResult> verifyOtp({
    required String flowSecret,
    required String code,
  }) async {
    try {
      final response = await _http.dio.post(
        'api/v1/auth/login/verify-otp/',
        data: {'flow_secret': flowSecret, 'code': code},
      );
      return _parseResult(response);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return LoginFlowResult.error(
          _detail(e) ?? 'El código no es válido o ya expiró.',
        );
      }
      return _mapDioError(e);
    } catch (e) {
      return LoginFlowResult.error('Error inesperado: $e');
    }
  }

  /// POST /api/v1/auth/login/request-admin-approval/
  /// Convierte un OTP vigente en aprobación administrativa por código.
  /// El backend NO re-emite flow_secret: se reutiliza el existente.
  Future<LoginFlowResult> requestAdminApproval({
    required String flowSecret,
  }) async {
    try {
      final response = await _http.dio.post(
        'api/v1/auth/login/request-admin-approval/',
        data: {'flow_secret': flowSecret},
      );
      return _parseResult(response);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return LoginFlowResult.gone(
          _detail(e) ??
              'La verificación ya no está disponible. Inicia nuevamente.',
        );
      }
      return _mapDioError(e);
    } catch (e) {
      return LoginFlowResult.error('Error inesperado: $e');
    }
  }

  /// POST /api/v1/auth/device-approval/status/  (polling)
  Future<LoginFlowResult> checkApprovalStatus({
    required String flowSecret,
  }) async {
    try {
      final response = await _http.dio.post(
        'api/v1/auth/device-approval/status/',
        data: {'flow_secret': flowSecret},
      );
      return _parseResult(response);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return LoginFlowResult.gone(
          _detail(e) ?? 'La solicitud no existe o ya no está disponible.',
        );
      }
      return _mapDioError(e);
    } catch (e) {
      return LoginFlowResult.error('Error inesperado: $e');
    }
  }

  LoginFlowResult _parseResult(Response response) {
    if (response.data is! Map<String, dynamic>) {
      return LoginFlowResult.error('Respuesta inválida del servidor');
    }
    return LoginFlowResult.fromJson(response.data);
  }

  String? _detail(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }
    return null;
  }

  LoginFlowResult _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return LoginFlowResult.error(
          'Tiempo de conexión agotado. Verifica tu conexión a internet.',
          isNetworkError: true,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return LoginFlowResult.error(
          'No se pudo conectar al servidor. Verifica tu conexión a internet.',
          isNetworkError: true,
        );
      default:
        return LoginFlowResult.error(
          _detail(e) ?? 'Error de red: ${e.message}',
        );
    }
  }
}
