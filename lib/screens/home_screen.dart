import 'package:flutter/material.dart';

import '../models/gas_station.dart';
import '../models/place_suggestion.dart';
import '../theme/app_theme.dart';
import '../widgets/map_preview.dart';
import '../widgets/mascot.dart';
import '../widgets/station_card.dart';
import 'station_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.stations,
    required this.cheapest,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.favoriteIds,
    required this.onToggleFavorite,
    this.suggestions = const [],
    this.onSuggestionSelected,
    this.referencePlaceLabel,
    this.onUseMyLocation,
    required this.onCalibrateLocation,
    this.userLatitude,
    this.userLongitude,
    this.focusLatitude,
    this.focusLongitude,
  });

  final List<GasStation> stations;
  final GasStation? cheapest;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefresh;
  final Set<String> favoriteIds;
  final ValueChanged<String> onToggleFavorite;

  /// Sugerencias de lugares para el texto buscado actualmente.
  final List<PlaceSuggestion> suggestions;
  final ValueChanged<PlaceSuggestion>? onSuggestionSelected;

  /// Nombre del lugar elegido como referencia, o `null` si se está usando
  /// la ubicación del usuario.
  final String? referencePlaceLabel;
  final Future<void> Function()? onUseMyLocation;

  /// Vuelve a obtener la ubicación GPS del usuario y recentra el mapa,
  /// siempre disponible mediante el botón flotante sobre el mapa.
  final Future<void> Function() onCalibrateLocation;

  final double? userLatitude;
  final double? userLongitude;

  /// Punto en el que centrar el mapa (lugar buscado), si hay uno.
  final double? focusLatitude;
  final double? focusLongitude;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _searchController = TextEditingController(
    text: widget.searchQuery,
  );

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stations = widget.stations;
    final cheapest = widget.cheapest;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                const Mascot(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola! 👋',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        'PrecioBencina',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Encontremos la bencina más barata cerca de ti',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              onChanged: widget.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar bencinera o dirección...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textMuted,
                ),
                suffixIcon: widget.searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Borrar búsqueda',
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          widget.onSearchChanged('');
                        },
                      ),
              ),
            ),
            if (widget.suggestions.isNotEmpty)
              _PlaceSuggestionsList(
                suggestions: widget.suggestions,
                onTap: (place) {
                  _searchController.clear();
                  widget.onSuggestionSelected?.call(place);
                },
              ),
            if (widget.referencePlaceLabel != null)
              _ReferencePlaceChip(
                label: widget.referencePlaceLabel!,
                onUseMyLocation: widget.onUseMyLocation,
              ),
            const SizedBox(height: 16),
            if (cheapest != null) ...[
              StationCard(
                station: cheapest,
                isCheapest: true,
                isFavorite: widget.favoriteIds.contains(cheapest.id),
                onToggleFavorite: () => widget.onToggleFavorite(cheapest.id),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StationDetailScreen(
                      station: cheapest,
                      isCheapest: true,
                      isFavorite: widget.favoriteIds.contains(cheapest.id),
                      onToggleFavorite: () =>
                          widget.onToggleFavorite(cheapest.id),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else
              const _EmptyResultsMessage(),
            Stack(
              children: [
                MapPreview(
                  stations: stations,
                  cheapestId: cheapest?.id ?? '',
                  userLatitude: widget.userLatitude,
                  userLongitude: widget.userLongitude,
                  focusLatitude: widget.focusLatitude,
                  focusLongitude: widget.focusLongitude,
                  onStationTap: (station) => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StationDetailScreen(
                        station: station,
                        isCheapest: station.id == cheapest?.id,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: _GpsButton(onPressed: widget.onCalibrateLocation),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista desplegable con sugerencias de lugares (ciudades, direcciones)
/// que coinciden con el texto buscado.
class _PlaceSuggestionsList extends StatelessWidget {
  const _PlaceSuggestionsList({required this.suggestions, required this.onTap});

  final List<PlaceSuggestion> suggestions;
  final ValueChanged<PlaceSuggestion> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final place in suggestions)
            ListTile(
              leading: const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                place.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              onTap: () => onTap(place),
            ),
        ],
      ),
    );
  }
}

/// Aviso de que las estaciones mostradas son cercanas a un lugar buscado
/// (no a la ubicación del usuario), con un acceso directo para volver a
/// usar el GPS.
class _ReferencePlaceChip extends StatelessWidget {
  const _ReferencePlaceChip({required this.label, this.onUseMyLocation});

  final String label;
  final Future<void> Function()? onUseMyLocation;

  @override
  Widget build(BuildContext context) {
    final shortLabel = label.split(',').take(2).join(',');
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          const Icon(Icons.place, size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Mostrando bencinas cerca de $shortLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.primaryDark),
            ),
          ),
          if (onUseMyLocation != null)
            TextButton.icon(
              onPressed: onUseMyLocation,
              icon: const Icon(Icons.my_location, size: 16),
              label: const Text('Mi ubicación'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: AppColors.primaryDark,
              ),
            ),
        ],
      ),
    );
  }
}

/// Mensaje mostrado cuando no hay estaciones que coincidan con el
/// combustible seleccionado o el texto buscado.
class _EmptyResultsMessage extends StatelessWidget {
  const _EmptyResultsMessage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'No encontramos estaciones que coincidan con tu búsqueda o filtro.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

/// Botón circular flotante sobre el mapa para volver a obtener la ubicación
/// GPS del usuario y recentrar el mapa, similar al de apps como Uber o
/// Google Maps.
class _GpsButton extends StatelessWidget {
  const _GpsButton({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: AppColors.surface,
      elevation: 3,
      child: Tooltip(
        message: 'Recalibrar ubicación',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.gps_fixed, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
