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

    test(
      'conserva las 20 más cercanas por combustible y no descarta el GLP '
      'aunque esté más lejos',
      () async {
        SharedPreferences.setMockInitialValues({});

        Map<String, dynamic> row(
          String codigo,
          double lng,
          Map<String, dynamic> precios,
        ) => {
          'codigo': codigo,
          'distribuidor': {'marca': 'Marca $codigo'},
          'ubicacion': {
            'direccion': 'Calle $codigo',
            'latitud': '0',
            'longitud': '$lng',
          },
          'precios': precios,
        };

        // 25 estaciones con 95 cerca (lng 0.01..0.25) y 12 con GLP más lejos
        // (lng 0.5..6.0): el GLP no debe quedar fuera por un tope global.
        final rows = [
          for (var i = 1; i <= 25; i++)
            row('g95-$i', 0.01 * i, {
              'A95': {'precio': '1000'},
            }),
          for (var i = 1; i <= 12; i++)
            row('glp-$i', 0.5 * i, {
              'GLP': {'precio': '500'},
            }),
        ];

        final repository = GasStationRepository(
          service: _FakeCneFuelPriceService(rows: rows),
        );

        final result = await repository.fetchNearbyStations(
          latitude: 0,
          longitude: 0,
        );

        final gas95 = result.stations
            .where((s) => s.fuelType == FuelType.gas95)
            .toList();
        final glp = result.stations
            .where((s) => s.fuelType == FuelType.glp)
            .toList();

        expect(gas95, hasLength(20)); // tope de 20 por combustible
        expect(glp, hasLength(12)); // todas (≥10) pese a estar más lejos
        // Las 20 de 95 son las más cercanas (g95-1..g95-20), no g95-25.
        expect(gas95.map((s) => s.id), isNot(contains('g95-25-gas95')));
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
