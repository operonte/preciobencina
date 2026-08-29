import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Colores corporativos aproximados de las principales cadenas de
/// bencineras en Chile, usados para distinguir rápidamente cada estación
/// en el mapa y en las listas. Si la marca no es reconocida, se usa
/// `AppColors.primaryDark` (no `primary`: este color también se usa como
/// ícono/fondo con texto encima, y `primary` no cumple el contraste
/// mínimo WCAG AA).
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

/// Caché de [brandColor] por nombre exacto de estación: se llama en cada
/// build de cada tarjeta y cada pin del mapa, y la búsqueda es lineal sobre
/// [_brandColors], así que vale la pena no repetirla para el mismo nombre.
final _brandColorCache = <String, Color>{};

/// Devuelve el color corporativo asociado a [marca], o `AppColors.primaryDark`
/// si no se reconoce la marca.
Color brandColor(String marca) => _brandColorCache.putIfAbsent(marca, () {
  final upper = marca.toUpperCase();
  for (final entry in _brandColors.entries) {
    if (upper.contains(entry.key)) return entry.value;
  }
  return AppColors.primaryDark;
});

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

/// Caché de [brandLogo] por nombre exacto de estación, por la misma razón
/// que [_brandColorCache].
final _brandLogoCache = <String, String?>{};

/// Devuelve la ruta del logo de [marca], o `null` si no hay uno disponible.
String? brandLogo(String marca) => _brandLogoCache.putIfAbsent(marca, () {
  final upper = marca.toUpperCase();
  for (final entry in _brandLogos.entries) {
    if (upper.contains(entry.key)) return entry.value;
  }
  return null;
});
