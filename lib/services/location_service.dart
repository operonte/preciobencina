import 'package:geolocator/geolocator.dart';

/// Obtiene la ubicación actual del usuario, manejando permisos y el caso
/// en que el servicio de ubicación esté deshabilitado.
class LocationService {
  /// Devuelve la posición actual, o `null` si el usuario no otorgó permiso,
  /// el servicio de ubicación está deshabilitado, o la plataforma no lo
  /// soporta.
  Future<Position?> getCurrentPosition() async {
    try {
      return await _resolvePosition().timeout(const Duration(seconds: 8));
    } catch (_) {
      return null;
    }
  }

  Future<Position?> _resolvePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
  }
}
