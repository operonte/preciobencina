import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:preciobencina/models/gas_station.dart';
import 'package:preciobencina/repositories/gas_station_repository.dart';
import 'package:preciobencina/services/cne_fuel_price_service.dart';

/// Servicio de prueba que devuelve filas predefinidas o lanza un error,
/// sin hacer llamadas de red reales.
class _FakeCneFuelPriceService extends CneFuelPriceService {
  _FakeCneFuelPriceService({this.rows, this.error});

  final List<Map<String, dynamic>>? rows;
  final Object? error;

  @override
  Future<List<Map<String, dynamic>>> fetchStationPrices() async {
    if (error != null) throw error!;
    return rows ?? [];
  }
}

const _cacheKey = 'cached_stations_v1';

void main() {
  group('GasStationRepository', () {
    test('devuelve datos en vivo y los guarda en caché', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = GasStationRepository(
        service: _FakeCneFuelPriceService(
          rows: [
            {
              'codigo': 'ab110101',
              'distribuidor': {'marca': 'Copec Manuel Montt'},
              'ubicacion': {'direccion': 'Manuel Montt 567'},
              'precios': {
                'A95': {'precio': '1205'},
              },
            },
          ],
        ),
      );

      final result = await repository.fetchNearbyStations();

      expect(result.source, DataSource.live);
      expect(result.isLiveData, isTrue);
      expect(result.stations, hasLength(1));
      expect(result.stations.first.name, 'Copec Manuel Montt');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_cacheKey), isNotNull);
    });

    test('usa el snapshot de estaciones cuando falla y no hay caché', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = GasStationRepository(
        service: _FakeCneFuelPriceService(
          error: CneApiException('sin auth_key'),
        ),
        bundledStationsLoader: ({bundle}) async => [
          const GasStation(
            id: 'bundled-1',
            name: 'Copec Snapshot',
            address: 'Av. Siempre Viva 123',
            distanceKm: 0,
            fuelType: FuelType.gas95,
            price: 1234,
            lastUpdated: 'hace 2 días',
          ),
        ],
      );

      final result = await repository.fetchNearbyStations();

      expect(result.source, DataSource.bundled);
      expect(result.isLiveData, isFalse);
      expect(result.stations, hasLength(1));
      expect(result.stations.first.name, 'Copec Snapshot');
    });

    test(
      'usa datos de ejemplo si tampoco se puede cargar el snapshot',
      () async {
        SharedPreferences.setMockInitialValues({});
        final repository = GasStationRepository(
          service: _FakeCneFuelPriceService(
            error: CneApiException('sin auth_key'),
          ),
          bundledStationsLoader: ({bundle}) async => [],
        );

        final result = await repository.fetchNearbyStations();

        expect(result.source, DataSource.mock);
        expect(result.isLiveData, isFalse);
        expect(result.stations, isNotEmpty);
      },
    );

    test('usa la caché guardada cuando falla y hay caché previa', () async {
      final cachedStation = const GasStation(
        id: 'cached-1',
        name: 'Estación en caché',
        address: 'Calle Falsa 123',
        distanceKm: 0.5,
        fuelType: FuelType.gas95,
        price: 1111,
        lastUpdated: 'hace 1 día',
      );
      SharedPreferences.setMockInitialValues({
        _cacheKey: jsonEncode([cachedStation.toJson()]),
      });

      final repository = GasStationRepository(
        service: _FakeCneFuelPriceService(error: CneApiException('sin red')),
      );

      final result = await repository.fetchNearbyStations();

      expect(result.source, DataSource.cached);
      expect(result.stations, hasLength(1));
      expect(result.stations.first.name, 'Estación en caché');
    });
  });
}
