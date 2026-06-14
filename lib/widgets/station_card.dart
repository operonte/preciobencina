import 'package:flutter/material.dart';

import '../models/gas_station.dart';
import '../theme/app_theme.dart';
import '../theme/brand_colors.dart';

/// Tarjeta de estación usada en la lista y como destacado "la más barata".
class StationCard extends StatelessWidget {
  const StationCard({
    super.key,
    required this.station,
    this.isCheapest = false,
    this.onTap,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  final GasStation station;
  final bool isCheapest;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCheapest
                      ? AppColors.accentGreenLight
                      : brandColor(station.name).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  isCheapest ? Icons.star_rounded : Icons.local_gas_station,
                  color: isCheapest
                      ? AppColors.accentGreen
                      : brandColor(station.name),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCheapest)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          'LA MÁS BARATA',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    Text(
                      station.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${station.distanceKm.toStringAsFixed(1)} km · actualizado ${station.lastUpdated}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (onToggleFavorite != null)
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite
                              ? AppColors.accentGreen
                              : AppColors.textMuted,
                        ),
                        onPressed: onToggleFavorite,
                      ),
                    ),
                  Text(
                    station.formattedPrice,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isCheapest
                          ? AppColors.accentGreen
                          : AppColors.primary,
                    ),
                  ),
                  Text(
                    station.fuelType.unitLabel,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
