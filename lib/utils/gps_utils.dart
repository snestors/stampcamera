import 'package:geolocator/geolocator.dart';

/// Obtiene el GPS del dispositivo o retorna Position con lat:0, lng:0 si no hay permisos.
Future<Position> obtenerGpsSeguro() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return _defaultPosition();
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(accuracy: LocationAccuracy.high),
    );

    return position;
  } catch (_) {
    return _defaultPosition();
  }
}

Position _defaultPosition() {
  return Position(
    latitude: 0.0,
    longitude: 0.0,
    timestamp: DateTime.now(),
    accuracy: 0.0,
    altitude: 0.0,
    heading: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
    altitudeAccuracy: 0.0,
    headingAccuracy: 0.0,
  );
}
