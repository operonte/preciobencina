import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Colores corporativos aproximados de las principales cadenas de
/// bencineras en Chile, usados para distinguir rápidamente cada estación
/// en el mapa y en las listas. Si la marca no es reconocida, se usa el
/// color primario de la app.
const _brandColors = <String, Color>{
  'COPEC': Color(0xFFE2231A),
  'SHELL': Color(0xFFFFD500),
  'PETROBRAS': Color(0xFF00A859),
  'PETROBRAS BRASIL': Color(0xFF00A859),
  'ARAMCO': Color(0xFF0F4C81),
  'PETROCHILE': Color(0xFF0F4C81),
  'ENEX': Color(0xFFF7941E),
  'YPF': Color(0xFF005BAA),
  'TERPEL': Color(0xFFE2231A),
};

/// Devuelve el color corporativo asociado a [marca], o el color primario de
/// la app si no se reconoce la marca.
Color brandColor(String marca) {
  final upper = marca.toUpperCase();
  for (final entry in _brandColors.entries) {
    if (upper.contains(entry.key)) return entry.value;
  }
  return AppColors.primary;
}

/// Color de texto/ícono con buen contraste sobre [brandColor]. Las marcas
/// con fondos claros (ej. amarillo) necesitan ícono oscuro.
Color brandForeground(Color background) {
  return background.computeLuminance() > 0.5
      ? AppColors.textDark
      : Colors.white;
}

/// Logos disponibles para las cadenas de bencineras más comunes en Chile.
/// Si la marca no tiene logo, se usa [brandColor] con un ícono genérico.
const _brandLogos = <String, String>{
  'COPEC': 'assets/iconos/copec_icono.png',
  'SHELL': 'assets/iconos/shell_icono.png',
  'ARAMCO': 'assets/iconos/icono_aramco.png',
  'GULF': 'assets/iconos/gulf_icono.png',
  'PETROBRAS': 'assets/iconos/petrobras_icono.png',
  'GASCO': 'assets/iconos/gasco_icono.png',
  'ABASTIBLE': 'assets/iconos/abastible_icono.png',
  'LIPIGAS': 'assets/iconos/lipigas_icono.png',
  'PETROPRIX': 'assets/iconos/petroprix_icono.png',
  'JLC': 'assets/iconos/jlc_icono.png',
  'HN': 'assets/iconos/hn_icono.png',
};

/// Devuelve la ruta del logo de [marca], o `null` si no hay uno disponible.
String? brandLogo(String marca) {
  final upper = marca.toUpperCase();
  for (final entry in _brandLogos.entries) {
    if (upper.contains(entry.key)) return entry.value;
  }
  return null;
}
