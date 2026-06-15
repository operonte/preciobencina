import 'package:geolocator/geolocator.dart';

/// Estado de disponibilidad de la ubicación del dispositivo.
enum LocationAvailability {
  /// El servicio de ubicación está activo y la app tiene permiso.
  available,

  /// El GPS/servicio de ubicación está desactivado en el dispositivo.
  serviceDisabled,

  /// La app no tiene permiso para acceder a la ubicación.
  permissionDenied,
}

/// Obtiene la ubicación actual del usuario, manejando permisos y el caso
/// en que el servicio de ubicación esté deshabilitado.
class LocationService {
  /// Devuelve la posición actual, o `null` si el usuario no otorgó permiso,
  /// el servicio de ubicación está deshabilitado, o la plataforma no lo
  /// soporta.
  Future<Position?> getCurrentPosition() async {
    try {
      if (await checkAvailability() != LocationAvailability.available) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      return null;
    }
  }

  /// Indica si se puede obtener la ubicación, y si no, por qué (GPS
  /// desactivado o permiso no otorgado). Si la plataforma no soporta
  /// geolocalización (p. ej. en tests), se asume que falta el permiso.
  Future<LocationAvailability> checkAvailability() async {
    try {
      return await _resolveAvailability().timeout(const Duration(seconds: 8));
    } catch (_) {
      return LocationAvailability.permissionDenied;
    }
  }

  Future<LocationAvailability> _resolveAvailability() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAvailability.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return LocationAvailability.permissionDenied;
    }

    return LocationAvailability.available;
  }

  /// Abre los ajustes de ubicación del sistema (para activar el GPS).
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  /// Abre los ajustes de la app (para otorgar el permiso de ubicación).
  Future<void> openAppSettings() => Geolocator.openAppSettings();
}
