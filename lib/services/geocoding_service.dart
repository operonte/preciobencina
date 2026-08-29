import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/place_suggestion.dart';

/// Resultado de una búsqueda de lugares: `suggestions` vacío puede
/// significar que no hubo coincidencias, o que la búsqueda falló (sin
/// conexión, timeout, error del servidor). `failed` distingue un caso del
/// otro para que la UI pueda avisar solo en el segundo.
typedef GeocodingResult = ({List<PlaceSuggestion> suggestions, bool failed});

const _noResults = (suggestions: <PlaceSuggestion>[], failed: false);
const _searchFailed = (suggestions: <PlaceSuggestion>[], failed: true);

/// Busca lugares (ciudades, comunas, direcciones) usando Nominatim, el
/// servicio de geocodificación de OpenStreetMap, para que el usuario pueda
/// centrar el mapa en cualquier punto de Chile sin usar su GPS.
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://nominatim.openstreetmap.org/search';

  /// Devuelve hasta 5 lugares que coincidan con [query].
  Future<GeocodingResult> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return _noResults;

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
          .get(
            uri,
            headers: {
              'Accept-Language': 'es',
              // Nominatim bloquea con 403 los User-Agent genéricos de las
              // librerías HTTP; hay que identificar la app explícitamente.
              // https://operations.osmfoundation.org/policies/nominatim/
              'User-Agent': 'PrecioBencina (cl.preciobencina.preciobencina)',
            },
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return _searchFailed;

      final body = jsonDecode(response.body);
      if (body is! List) return _searchFailed;

      final suggestions = body
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
      return (suggestions: suggestions, failed: false);
    } catch (_) {
      return _searchFailed;
    }
  }
}
