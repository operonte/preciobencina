import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/gas_station.dart';
import '../theme/app_theme.dart';
import '../theme/brand_colors.dart';

/// Centro por defecto (Providencia, Santiago) usado cuando no hay
/// coordenadas de estaciones ni del usuario disponibles.
const _defaultCenter = LatLng(-33.4280, -70.6150);

/// Mapa real (OpenStreetMap) con pines de precio por estación y la
/// ubicación del usuario, si está disponible.
class MapPreview extends StatefulWidget {
  const MapPreview({
    super.key,
    required this.stations,
    required this.cheapestId,
    this.onStationTap,
    this.userLatitude,
    this.userLongitude,
    this.focusLatitude,
    this.focusLongitude,
  });

  final List<GasStation> stations;
  final String cheapestId;
  final ValueChanged<GasStation>? onStationTap;
  final double? userLatitude;
  final double? userLongitude;

  /// Punto en el que centrar el mapa (ej. un lugar buscado). Tiene
  /// prioridad sobre [userLatitude]/[userLongitude].
  final double? focusLatitude;
  final double? focusLongitude;

  /// Punto en el que centrar el mapa según las coordenadas dadas, con la
  /// prioridad: lugar buscado > ubicación del usuario > primera estación
  /// con coordenadas > centro por defecto.
  LatLng _center(List<GasStation> located) {
    if (focusLatitude != null && focusLongitude != null) {
      return LatLng(focusLatitude!, focusLongitude!);
    }
    if (userLatitude != null && userLongitude != null) {
      return LatLng(userLatitude!, userLongitude!);
    }
    if (located.isNotEmpty) {
      return LatLng(located.first.latitude!, located.first.longitude!);
    }
    return _defaultCenter;
  }

  @override
  State<MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview> {
  final _mapController = MapController();

  @override
  void didUpdateWidget(MapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCenter = oldWidget._center(_locatedStations(oldWidget));
    final newCenter = widget._center(_locatedStations(widget));
    if (oldCenter != newCenter) {
      _mapController.move(newCenter, _mapController.camera.zoom);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<GasStation> _locatedStations(MapPreview widget) => widget.stations
      .where((s) => s.latitude != null && s.longitude != null)
      .toList();

  @override
  Widget build(BuildContext context) {
    final located = _locatedStations(widget);
    final center = widget._center(located);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 1.1,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 14,
            minZoom: 4,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'cl.preciobencina.preciobencina',
            ),
            MarkerLayer(
              markers: [
                if (widget.userLatitude != null && widget.userLongitude != null)
                  Marker(
                    point: LatLng(widget.userLatitude!, widget.userLongitude!),
                    width: 24,
                    height: 24,
                    child: const _UserDot(),
                  ),
                for (final station in located)
                  Marker(
                    point: LatLng(station.latitude!, station.longitude!),
                    width: 90,
                    height: 64,
                    alignment: Alignment.topCenter,
                    child: _PricePin(
                      station: station,
                      isCheapest: station.id == widget.cheapestId,
                      onTap: () => widget.onStationTap?.call(station),
                    ),
                  ),
              ],
            ),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFF4285F4),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4285F4).withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _PricePin extends StatelessWidget {
  const _PricePin({
    required this.station,
    required this.isCheapest,
    this.onTap,
  });

  final GasStation station;
  final bool isCheapest;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isCheapest ? AppColors.accentGreen : AppColors.primary;
    final badgeColor = brandColor(station.name);
    final logo = brandLogo(station.name);
    return GestureDetector(
      onTap: onTap,
      child: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              padding: logo != null ? const EdgeInsets.all(4) : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: logo != null ? Colors.white : badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: logo != null
                  ? ClipOval(child: Image.asset(logo, fit: BoxFit.contain))
                  : Icon(
                      Icons.local_gas_station,
                      size: 16,
                      color: brandForeground(badgeColor),
                    ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                station.formattedPrice,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
