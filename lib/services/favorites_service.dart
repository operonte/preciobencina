import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

/// Guarda localmente los ids de las estaciones marcadas como favoritas.
class FavoritesService {
  static const _key = 'favorite_station_ids';

  /// Ids favoritos guardados, o un set vacío si no hay ninguno o no se
  /// pudo leer la preferencia (en vez de que la app falle al abrir).
  Future<Set<String>> getFavoriteIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_key) ?? const []).toSet();
    } catch (error) {
      developer.log(
        'No se pudieron leer los favoritos guardados: $error',
        name: 'FavoritesService',
      );
      return const {};
    }
  }

  /// Agrega o quita [stationId] de los favoritos y devuelve el set
  /// resultante. Si falla el guardado, igual devuelve el set actualizado
  /// (la UI refleja el cambio) pero este no persistirá entre sesiones.
  Future<Set<String>> toggleFavorite(String stationId) async {
    final current = await getFavoriteIds();
    if (!current.remove(stationId)) {
      current.add(stationId);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, current.toList());
    } catch (error) {
      developer.log(
        'No se pudo guardar el cambio de favoritos: $error',
        name: 'FavoritesService',
      );
    }
    return current;
  }
}
