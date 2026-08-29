import 'package:flutter/material.dart';

import '../models/gas_station.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_results_message.dart';
import '../widgets/official_source_link.dart';
import '../widgets/station_card.dart';
import 'station_detail_screen.dart';

class ListScreen extends StatelessWidget {
  const ListScreen({
    super.key,
    required this.stations,
    required this.cheapest,
    required this.sortOrder,
    required this.onRefresh,
    required this.favoriteIds,
    required this.onToggleFavorite,
    this.isDataUnavailable = false,
  });

  final List<GasStation> stations;
  final GasStation? cheapest;
  final SortOrder sortOrder;
  final Future<void> Function() onRefresh;
  final Set<String> favoriteIds;
  final ValueChanged<String> onToggleFavorite;

  /// `true` cuando no se pudo obtener ningún dato (ni en vivo, ni en caché,
  /// ni el snapshot incluido).
  final bool isDataUnavailable;

  @override
  Widget build(BuildContext context) {
    final sortedStations = [...stations]
      ..sort(
        (a, b) => sortOrder == SortOrder.distance
            ? a.distanceKm.compareTo(b.distanceKm)
            : _comparePrices(a.price, b.price),
      );

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              'Estaciones cercanas',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              sortOrder == SortOrder.distance
                  ? 'Ordenadas de más cercana a más lejana'
                  : 'Ordenadas de menor a mayor precio',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            if (sortedStations.isEmpty)
              EmptyResultsMessage(
                message: isDataUnavailable
                    ? 'No pudimos cargar los precios. Revisa tu conexión '
                          'e inténtalo de nuevo.'
                    : 'No encontramos estaciones que coincidan con tu '
                          'búsqueda o filtro.',
                onRetry: isDataUnavailable ? onRefresh : null,
              )
            else
              for (final station in sortedStations)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: StationCard(
                    station: station,
                    isCheapest: station.id == cheapest?.id,
                    isFavorite: favoriteIds.contains(station.id),
                    onToggleFavorite: () => onToggleFavorite(station.id),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StationDetailScreen(
                          station: station,
                          isCheapest: station.id == cheapest?.id,
                          isFavorite: favoriteIds.contains(station.id),
                          onToggleFavorite: () => onToggleFavorite(station.id),
                        ),
                      ),
                    ),
                  ),
                ),
            if (sortedStations.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Center(child: OfficialSourceLink()),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compara precios que pueden ser `null` ("No informado"), dejando esas
/// estaciones al final del orden por precio.
int _comparePrices(double? a, double? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}
