import 'package:flutter/material.dart';

class ConnectionErrorScreen extends StatelessWidget {
  final Object? error;
  final VoidCallback? onRetry;

  const ConnectionErrorScreen({super.key, this.error, this.onRetry});

  /// Detecta si es un error de conexión basado en el mensaje
  bool _isConnectionError(Object? error) {
    if (error == null) return false;

    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
        errorString.contains('failed to connect') ||
        errorString.contains('connection refused') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('timeout') ||
        errorString.contains('connection failed') ||
        errorString.contains('no address associated with hostname') ||
        errorString.contains('connection error') ||
        errorString.contains('network error') ||
        errorString.contains('sin conexión');
  }

  @override
  Widget build(BuildContext context) {
    final isConnectionError = _isConnectionError(error);

    // Si no es error de conexión, mostrar error genérico
    if (!isConnectionError && error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              if (onRetry != null)
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Reintentar'),
                ),
            ],
          ),
        ),
      );
    }

    // Pantalla de error de conexión
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Sin conexión',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verifica tu conexión a internet\ne intenta nuevamente',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            if (onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
          ],
        ),
      ),
    );
  }
}
