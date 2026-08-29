import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

/// Enlace visible a la fuente oficial de los precios (CNE), requerido para
/// cumplir la política de afirmaciones engañosas de Google Play: cualquier
/// dato atribuido a un organismo gubernamental debe tener un link claro y
/// accesible a la fuente original. Se muestra en Mapa, Lista y Detalle para
/// que sea visible sin importar qué pantalla vea quien revisa la app.
class OfficialSourceLink extends StatelessWidget {
  const OfficialSourceLink({super.key});

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse('https://www.cne.cl');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(6),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_outlined,
                size: 14,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: 4),
              Text(
                'Fuente oficial: Comisión Nacional de Energía (cne.cl)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primaryDark,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
