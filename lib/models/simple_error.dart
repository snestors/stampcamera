// lib/models/simple_error.dart
class SimpleError {
  final String message;
  final bool isConnectionError;

  SimpleError(this.message, {this.isConnectionError = false});

  static SimpleError fromError(dynamic error) {
    // Si es error de conexión, mostrar pantalla especial
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Failed to connect') ||
        error.toString().contains('Connection refused') ||
        error.toString().contains('Network is unreachable')) {
      return SimpleError('Sin conexión', isConnectionError: true);
    }

    // Para otros errores, mostrar mensaje genérico
    return SimpleError('Error al procesar la solicitud');
  }
}
