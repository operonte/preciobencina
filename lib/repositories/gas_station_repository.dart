import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/bundled_stations.dart' as bundled;
import '../data/mock_stations.dart';
import '../models/gas_station.dart';
import '../services/cne_fuel_price_service.dart';

/// Origen de los datos devueltos por [GasStationRepository].
enum DataSource {
  /// Datos obtenidos en este momento desde la API de la CNE.
  live,

  /// Última respuesta válida de la CNE, guardada localmente (sin conexión).
  cached,

  /// Snapshot de estaciones reales incluido con la app, usado cuando no hay
  /// datos en vivo ni en caché.
  bundled,

  /// Datos de ejemplo (último recurso, si ni siquiera el snapshot está
  /// disponible).
  mock,
}

/// Resultado de cargar las estaciones: incluye la lista y de dónde vienen.
class GasStationsResult {
  const GasStationsResult({
    required this.stations,
    required this.source,
    this.cachedAt,
  });

  final List<GasStation> stations;
  final DataSource source;

  /// Momento en que se guardó la caché, solo aplica si [source] es
  /// [DataSource.cached].
  final DateTime? cachedAt;

  bool get isLiveData => source == DataSource.live;
}

/// Punto único de acceso a los datos de precios de combustible.
///
/// Intenta obtener datos en vivo desde la CNE. Si falla, recurre a la última
/// respuesta guardada en caché local; si tampoco existe, usa el snapshot de
/// estaciones reales incluido con la app ([loadBundledStations]); y si eso
/// también falla, cae a [mockStations] para que la app nunca se quede sin
/// nada que mostrar.
class GasStationRepository {
  GasStationRepository({
    CneFuelPriceService? service,
    Future<List<GasStation>> Function({AssetBundle? bundle})?
    bundledStationsLoader,
  }) : _service = service ?? CneFuelPriceService(),
       _loadBundledStations =
           bundledStationsLoader ?? bundled.loadBundledStations;

  static const _cacheKey = 'cached_stations_v1';
  static const _cacheTimestampKey = 'cached_stations_timestamp_v1';

  final CneFuelPriceService _service;
  final Future<List<GasStation>> Function({AssetBundle? bundle})
  _loadBundledStations;

  /// Número de estaciones cercanas a conservar. La CNE entrega ~2000
  /// estaciones a nivel nacional en cada consulta; quedarnos solo con las
  /// más cercanas mantiene la app, el mapa y la caché local livianos.
  ///
  /// Combustibles poco comunes (parafina, GLP) no los reporta cualquier
  /// estación, así que se conserva un margen mayor a 20 para que, al
  /// filtrar por uno de esos combustibles, sigan apareciendo resultados
  /// cercanos en vez de una lista vacía.
  static const _maxStations = 60;

  /// Obtiene las estaciones más cercanas a ([latitude], [longitude]) (la
  /// ubicación del usuario o un lugar buscado). Si no se entrega una
  /// ubicación, se toma una muestra arbitraria de estaciones.
  Future<GasStationsResult> fetchNearbyStations({
    double? latitude,
    double? longitude,
  }) async {
    try {
      var rows = await _service.fetchStationPrices();
      if (rows.isEmpty) {
        return _fallback(latitude: latitude, longitude: longitude);
      }

      if (latitude != null && longitude != null) {
        rows = [...rows]
          ..sort(
            (a, b) => _distanceFromRow(
              a,
              latitude,
              longitude,
            ).compareTo(_distanceFromRow(b, latitude, longitude)),
          );
      }
      if (rows.length > _maxStations) {
        rows = rows.sublist(0, _maxStations);
      }

      final stations = rows.expand(GasStation.fromCneStation).toList();
      await _saveToCache(stations);
      return GasStationsResult(stations: stations, source: DataSource.live);
    } catch (error) {
      developer.log(
        'No se pudieron obtener datos de la CNE, usando datos guardados o de ejemplo: $error',
        name: 'GasStationRepository',
      );
      return _fallback(latitude: latitude, longitude: longitude);
    }
  }

  /// Distancia en metros entre ([latitude], [longitude]) y la ubicación de
  /// [row]. Las estaciones sin coordenadas válidas quedan al final.
  double _distanceFromRow(
    Map<String, dynamic> row,
    double latitude,
    double longitude,
  ) {
    final ubicacion = row['ubicacion'] as Map?;
    final lat = double.tryParse(ubicacion?['latitud']?.toString() ?? '');
    final lng = double.tryParse(ubicacion?['longitud']?.toString() ?? '');
    if (lat == null || lng == null) return double.infinity;
    return Geolocator.distanceBetween(latitude, longitude, lat, lng);
  }

  /// Distancia en metros entre ([latitude], [longitude]) y [station]. Las
  /// estaciones sin coordenadas válidas quedan al final.
  double _distanceFromStation(
    GasStation station,
    double latitude,
    double longitude,
  ) {
    final lat = station.latitude;
    final lng = station.longitude;
    if (lat == null || lng == null) return double.infinity;
    return Geolocator.distanceBetween(latitude, longitude, lat, lng);
  }

  Future<GasStationsResult> _fallback({
    double? latitude,
    double? longitude,
  }) async {
    final cached = await _readCache();
    if (cached != null && cached.stations.isNotEmpty) {
      return GasStationsResult(
        stations: cached.stations,
        source: DataSource.cached,
        cachedAt: cached.cachedAt,
      );
    }

    try {
      var stations = await _loadBundledStations();
      if (stations.isEmpty) throw StateError('snapshot vacío');

      if (latitude != null && longitude != null) {
        stations = [...stations]
          ..sort(
            (a, b) => _distanceFromStation(
              a,
              latitude,
              longitude,
            ).compareTo(_distanceFromStation(b, latitude, longitude)),
          );
      }
      if (stations.length > _maxStations) {
        stations = stations.sublist(0, _maxStations);
      }
      return GasStationsResult(stations: stations, source: DataSource.bundled);
    } catch (error) {
      developer.log(
        'No se pudo cargar el snapshot de estaciones, usando datos de ejemplo: $error',
        name: 'GasStationRepository',
      );
      return GasStationsResult(stations: mockStations, source: DataSource.mock);
    }
  }

  Future<void> _saveToCache(List<GasStation> stations) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(stations.map((s) => s.toJson()).toList());
    await prefs.setString(_cacheKey, json);
    await prefs.setInt(
      _cacheTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<({List<GasStation> stations, DateTime? cachedAt})?>
  _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cacheKey);
      if (json == null) return null;

      final rows = jsonDecode(json) as List;
      final stations = rows
          .map((row) => GasStation.fromJson(row as Map<String, dynamic>))
          .toList();

      final timestamp = prefs.getInt(_cacheTimestampKey);
      final cachedAt = timestamp == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(timestamp);

      return (stations: stations, cachedAt: cachedAt);
    } catch (error) {
      developer.log(
        'No se pudo leer la caché local de estaciones: $error',
        name: 'GasStationRepository',
      );
      return null;
    }
  }
}
