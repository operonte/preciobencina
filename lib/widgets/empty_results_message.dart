import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Mensaje mostrado cuando no hay estaciones que mostrar: ya sea porque
/// ninguna coincide con el combustible/búsqueda actual, o porque no se pudo
/// obtener ningún dato (ni en vivo, ni en caché, ni el snapshot incluido).
class EmptyResultsMessage extends StatelessWidget {
  const EmptyResultsMessage({
    super.key,
    this.message =
        'No encontramos estaciones que coincidan con tu búsqueda o filtro.',
    this.onRetry,
  });

  /// Mensaje a mostrar. Por defecto, el de "sin coincidencias" (filtro o
  /// búsqueda). Pasar uno distinto para el caso de "no se pudo cargar nada".
  final String message;

  /// Acción de reintento, si aplica (ej. cuando no se pudo cargar ningún
  /// dato). `null` para el caso de "sin coincidencias", donde reintentar no
  /// tiene sentido.
  final Future<void> Function()? onRetry;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('Reintentar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
