import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de colores de PrecioBencina: cálida, alegre y pintoresca.
class AppColors {
  AppColors._();

  static const background = Color(0xFFFCF3E6);
  static const surface = Color(0xFFFFFFFF);
  // `primary` es solo decorativo (rellenos, bordes, acentos sin texto
  // encima): blanco sobre este naranja da 2.6:1, bajo el mínimo WCAG AA
  // (4.5:1 texto, 3:1 componentes gráficos). Cualquier texto o ícono que
  // vaya sobre `primary`, o que use `primary` como color de texto sobre
  // fondo claro, debe usar `primaryDark` en su lugar.
  static const primary = Color(0xFFFF7A30); // naranja bencina
  // Oscurecido respecto al naranja original (#E8650F, 3.0:1) para cumplir
  // el contraste mínimo WCAG AA en texto normal. Con margen: los banners de
  // estado lo muestran sobre `primary` al 12% de opacidad (no sobre
  // `background` puro), y ese fondo compuesto da menos contraste del que
  // parece a simple vista (ver test "cumple contraste y tamaño de tap
  // mínimos" en widget_test.dart, que corrió esto en carne propia).
  static const primaryDark = Color(0xFFA03F05);
  // "la más barata": oscurecido respecto al verde original (#2FAE60, 2.9:1)
  // para cumplir WCAG AA tanto como texto sobre fondo claro como con blanco
  // encima (5.4:1 en ambos casos).
  static const accentGreen = Color(0xFF1E7A43);
  static const accentGreenLight = Color(0xFFE3F6EA);
  static const textDark = Color(0xFF2B2118);
  // Oscurecido respecto al naranja original (#8A7B6E) para cumplir el
  // contraste mínimo WCAG AA (4.5:1) sobre `surface` en texto pequeño.
  static const textMuted = Color(0xFF6E5F53);
  static const mapBackground = Color(0xFFD9F1E6);
  static const mapRoad = Color(0xFFFFFFFF);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    final textTheme = GoogleFonts.fredokaTextTheme(
      base.textTheme,
    ).apply(bodyColor: AppColors.textDark, displayColor: AppColors.textDark);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.textMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: textTheme.labelMedium,
        unselectedLabelStyle: textTheme.labelMedium,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.titleMedium,
        ),
      ),
    );
  }
}
