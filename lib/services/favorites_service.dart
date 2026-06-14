import 'package:shared_preferences/shared_preferences.dart';

/// Guarda localmente los ids de las estaciones marcadas como favoritas.
class FavoritesService {
  static const _key = 'favorite_station_ids';

  Future<Set<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const []).toSet();
  }

  Future<Set<String>> toggleFavorite(String stationId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_key) ?? const []).toSet();
    if (!current.remove(stationId)) {
      current.add(stationId);
    }
    await prefs.setStringList(_key, current.toList());
    return current;
  }
}
