import 'package:flutter/material.dart';

import '../repositories/gas_station_repository.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

/// Aviso visible cuando no se están mostrando datos en vivo de la CNE:
/// indica si se trata de la última caché guardada o de datos de ejemplo.
class DataSourceBanner extends StatelessWidget {
  const DataSourceBanner({super.key, required this.result, required this.onRetry});

  final GasStationsResult result;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final message = switch (result.source) {
      DataSource.cached =>
        'Sin conexión: mostrando precios guardados${_cachedAtSuffix()}',
      DataSource.bundled =>
        'Mostrando precios de referencia (pueden no estar actualizados)',
      DataSource.mock =>
        'Mostrando datos de ejemplo mientras se cargan los '
            'precios reales',
      DataSource.live => '',
    };

    return Container(
      width: double.infinity,
      color: AppColors.primary.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.primaryDark),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: AppColors.primaryDark,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  String _cachedAtSuffix() {
    final cachedAt = result.cachedAt;
    if (cachedAt == null) return '';
    final h = cachedAt.hour.toString().padLeft(2, '0');
    final m = cachedAt.minute.toString().padLeft(2, '0');
    return ' (actualizados $h:$m)';
  }
}

/// Aviso visible cuando no se puede obtener la ubicación del usuario: indica
/// si el GPS está apagado o falta el permiso, con un acceso directo para
/// solucionarlo.
class LocationBanner extends StatelessWidget {
  const LocationBanner({
    super.key,
    required this.availability,
    required this.locationService,
  });

  final LocationAvailability availability;
  final LocationService locationService;

  @override
  Widget build(BuildContext context) {
    final (message, actionLabel, onAction) = switch (availability) {
      LocationAvailability.serviceDisabled => (
        'El GPS está desactivado',
        'Activar',
        locationService.openLocationSettings,
      ),
      LocationAvailability.permissionDenied => (
        'Falta el permiso de ubicación',
        'Ajustes',
        locationService.openAppSettings,
      ),
      LocationAvailability.available => ('', '', null),
    };

    return Container(
      width: double.infinity,
      color: AppColors.primary.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.location_off_outlined,
            size: 16,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.primaryDark),
            ),
          ),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: AppColors.primaryDark,
              ),
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }
}
