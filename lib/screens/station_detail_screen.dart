import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/gas_station.dart';
import '../theme/app_theme.dart';
import '../widgets/map_preview.dart';

class StationDetailScreen extends StatefulWidget {
  const StationDetailScreen({
    super.key,
    required this.station,
    this.isCheapest = false,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  final GasStation station;
  final bool isCheapest;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  late bool _isFavorite = widget.isFavorite;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final station = widget.station;
    final isCheapest = widget.isCheapest;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de estación'),
        actions: [
          if (widget.onToggleFavorite != null)
            IconButton(
              icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
              onPressed: () {
                setState(() => _isFavorite = !_isFavorite);
                widget.onToggleFavorite?.call();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            MapPreview(
              stations: [station],
              cheapestId: isCheapest ? station.id : '',
            ),
            const SizedBox(height: 20),
            if (isCheapest)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
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
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              station.address,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.fuelType.description,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${station.formattedPrice} / ${station.fuelType.unit}',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isCheapest
                                ? AppColors.accentGreen
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${station.distanceKm.toStringAsFixed(1)} km',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Actualizado ${station.lastUpdated}',
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openDirections(context),
              icon: const Icon(Icons.directions),
              label: const Text('Cómo llegar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Abre la app de mapas del dispositivo con la ruta hacia la estación.
  ///
  /// Si la estación tiene coordenadas, navega directo a ellas; si no,
  /// usa la dirección como término de búsqueda.
  Future<void> _openDirections(BuildContext context) async {
    final station = widget.station;
    final destination = (station.latitude != null && station.longitude != null)
        ? '${station.latitude},${station.longitude}'
        : Uri.encodeComponent('${station.name} ${station.address}');

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination',
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la app de mapas')),
      );
    }
  }
}
