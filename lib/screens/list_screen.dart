import 'package:flutter/material.dart';

import '../models/gas_station.dart';
import '../theme/app_theme.dart';
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
  });

  final List<GasStation> stations;
  final GasStation? cheapest;
  final SortOrder sortOrder;
  final Future<void> Function() onRefresh;
  final Set<String> favoriteIds;
  final ValueChanged<String> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final sortedStations = [...stations]
      ..sort(
        (a, b) => sortOrder == SortOrder.distance
            ? a.distanceKm.compareTo(b.distanceKm)
            : a.price.compareTo(b.price),
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
              Text(
                'No encontramos estaciones que coincidan con tu búsqueda o filtro.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
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
          ],
        ),
      ),
    );
  }
}
