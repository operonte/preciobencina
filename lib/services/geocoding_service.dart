import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/place_suggestion.dart';

/// Busca lugares (ciudades, comunas, direcciones) usando Nominatim, el
/// servicio de geocodificación de OpenStreetMap, para que el usuario pueda
/// centrar el mapa en cualquier punto de Chile sin usar su GPS.
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://nominatim.openstreetmap.org/search';

  /// Devuelve hasta 5 lugares que coincidan con [query], o una lista vacía
  /// si no hay coincidencias o la búsqueda falla (sin conexión, etc.).
  Future<List<PlaceSuggestion>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return const [];

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'q': trimmed,
        'format': 'jsonv2',
        'addressdetails': '0',
        'limit': '5',
        'countrycodes': 'cl',
      },
    );

    try {
      final response = await _client
          .get(uri, headers: {'Accept-Language': 'es'})
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return const [];

      final body = jsonDecode(response.body);
      if (body is! List) return const [];

      return body
          .whereType<Map<String, dynamic>>()
          .map((place) {
            final lat = double.tryParse(place['lat']?.toString() ?? '');
            final lon = double.tryParse(place['lon']?.toString() ?? '');
            final label = place['display_name']?.toString();
            if (lat == null || lon == null || label == null) return null;
            return PlaceSuggestion(label: label, latitude: lat, longitude: lon);
          })
          .whereType<PlaceSuggestion>()
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
