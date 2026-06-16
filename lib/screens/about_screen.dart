import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _version = '1.2.0';

  static const _faqs = [
    (
      '¿Por qué el precio no coincide con lo que vi en la bencinera?',
      'Los precios que muestra la app son los que cada bencinera declara a la '
          'Comisión Nacional de Energía (CNE). Si la estación no reportó a tiempo '
          'o entregó datos incorrectos, la app mostrará ese dato sin poder '
          'verificarlo. Las bencineras tienen hasta 2 horas para informar un '
          'cambio de precio.',
    ),
    (
      '¿Con qué frecuencia se actualizan los precios?',
      'Los datos se obtienen en tiempo real desde la API oficial de la CNE cada '
          'vez que abres la app o la refrescas. La demora en la actualización '
          'depende de cuándo la propia bencinera reporta el cambio a la CNE.',
    ),
    (
      '¿De dónde vienen los datos?',
      'Todos los precios provienen de la API pública de la Comisión Nacional de '
          'Energía (CNE), organismo del Estado chileno que regula y publica los '
          'precios de combustibles.',
    ),
    (
      '¿La app guarda mis datos personales?',
      'No. PrecioBencina no requiere registro ni cuenta. No almacenamos tu '
          'nombre, correo ni ningún dato de identificación personal. La ubicación '
          'GPS se usa solo en tu dispositivo para mostrar bencineras cercanas y '
          'nunca se envía a nuestros servidores.',
    ),
    (
      '¿Por qué no aparece una bencinera?',
      'Solo aparecen las estaciones de servicio registradas en el sistema de la '
          'CNE. Si una bencinera no está en el registro oficial, no podremos '
          'mostrarla.',
    ),
    (
      '¿Qué diferencia hay entre 95, 97, Diesel y Parafina?',
      'La Gasolina 95 y 97 son gasolinas para vehículos a bencina; el número '
          'indica el octanaje (mayor octanaje = mayor resistencia a la detonación). '
          'El Diesel es para vehículos con motor a petroleo. La Parafina se usa '
          'principalmente para calefacción.',
    ),
    (
      '¿Cómo funciona el buscador de direcciones?',
      'Puedes escribir una dirección, ciudad o lugar en el buscador para '
          'centrar el mapa en ese punto y ver las bencineras cercanas a él, sin '
          'necesidad de que estés físicamente ahí.',
    ),
    (
      '¿Para qué sirve el botón de GPS?',
      'Si el mapa quedó desfasado o cambiaste de ubicación, el botón de GPS '
          'vuelve a pedirle al dispositivo tu posición actual y recentra la vista.',
    ),
  ];

  Future<void> _launch(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace.')),
        );
      }
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'cristian.bravo.droguett@gmail.com',
      queryParameters: {'subject': 'PrecioBencina – Contacto'},
    );
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró un cliente de correo instalado.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 40),
        children: [
          _SectionHeader('Preguntas frecuentes'),
          ..._faqs.map(
            (faq) => ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 20),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Text(
                faq.$1,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              iconColor: AppColors.primary,
              collapsedIconColor: AppColors.textMuted,
              children: [
                Text(
                  faq.$2,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32, indent: 20, endIndent: 20),
          _SectionHeader('Links útiles'),
          _LinkTile(
            icon: Icons.local_gas_station_outlined,
            label: 'Ver precios en BencinaEnLínea',
            onTap: () => _launch(
              context,
              'https://www.bencinaenlinea.cl/#/busqueda_estaciones',
            ),
          ),
          _LinkTile(
            icon: Icons.report_problem_outlined,
            label: 'Reclamo en la SEC',
            onTap: () => _launch(context, 'https://www.sec.cl/reclamar-en-sec/'),
          ),
          _LinkTile(
            icon: Icons.account_balance_outlined,
            label: 'Reclamo vía ChileAtiende',
            onTap: () => _launch(
              context,
              'https://www.chileatiende.gob.cl/fichas/2692-reclamo-contra-empresas-y-organismos-fiscalizados-por-la-sec',
            ),
          ),
          _LinkTile(
            icon: Icons.gavel_outlined,
            label: 'Reclamo en SERNAC',
            onTap: () => _launch(
              context,
              'https://www.sernac.cl/portal/617/w3-article-9178.html',
            ),
          ),
          const Divider(height: 32, indent: 20, endIndent: 20),
          _SectionHeader('Legal'),
          _LinkTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Política de Privacidad',
            onTap: () => _launch(
              context,
              'https://preciobencina.web.app/privacidad',
            ),
          ),
          _LinkTile(
            icon: Icons.description_outlined,
            label: 'Términos de Uso',
            onTap: () => _launch(
              context,
              'https://preciobencina.web.app/terminos',
            ),
          ),
          const Divider(height: 32, indent: 20, endIndent: 20),
          _SectionHeader('Contacto'),
          _LinkTile(
            icon: Icons.mail_outline,
            label: 'Escríbenos',
            subtitle: 'cristian.bravo.droguett@gmail.com',
            onTap: () => _launchEmail(context),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'PrecioBencina v$_version\nDatos: Comisión Nacional de Energía (CNE)',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textDark),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textMuted,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
