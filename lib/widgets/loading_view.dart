import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot.dart';

/// Pantalla de carga mostrada mientras se obtienen los precios por primera
/// vez. La primera consulta a la CNE puede tardar varios segundos, así que
/// explicamos qué está pasando para que la espera no se sienta como un
/// error.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Mascot(size: 72),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 24),
                Text(
                  'Buscando las bencinas más baratas cerca de ti...',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Esto puede tardar unos segundos la primera vez',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
