import 'package:flutter_test/flutter_test.dart';
import 'package:preciobencina/models/gas_station.dart';

void main() {
  group('GasStation.fromCneStation', () {
    test('mapea una estación de la API a una GasStation por combustible', () {
      final updated = DateTime.now().subtract(const Duration(hours: 2));
      final fecha =
          '${updated.year.toString().padLeft(4, '0')}-'
          '${updated.month.toString().padLeft(2, '0')}-'
          '${updated.day.toString().padLeft(2, '0')}';
      final hora =
          '${updated.hour.toString().padLeft(2, '0')}:'
          '${updated.minute.toString().padLeft(2, '0')}:00';

      final stations = GasStation.fromCneStation({
        'codigo': 'ab110101',
        'distribuidor': {'marca': 'COPEC'},
        'ubicacion': {
          'direccion': 'Manuel Montt 567',
          'nombre_comuna': 'Providencia',
          'latitud': '-33.4309',
          'longitud': '-70.6256',
        },
        'precios': {
          'A95': {
            'precio': '1205',
            'fecha_actualizacion': fecha,
            'hora_actualizacion': hora,
          },
          'DI': {
            'precio': '1050',
            'fecha_actualizacion': fecha,
            'hora_actualizacion': hora,
          },
        },
      });

      expect(stations, hasLength(2));

      final gas95 = stations.firstWhere((s) => s.fuelType == FuelType.gas95);
      expect(gas95.id, 'ab110101-gas95');
      expect(gas95.name, 'COPEC');
      expect(gas95.address, 'Manuel Montt 567, Providencia');
      expect(gas95.price, 1205);
      expect(gas95.lastUpdated, 'hace 2 horas');
      expect(gas95.latitude, -33.4309);
      expect(gas95.longitude, -70.6256);

      final diesel = stations.firstWhere((s) => s.fuelType == FuelType.diesel);
      expect(diesel.price, 1050);
    });

    test('prefiere el precio de autoservicio sobre el atendido', () {
      final stations = GasStation.fromCneStation({
        'codigo': 'ab110101',
        'distribuidor': {'marca': 'COPEC'},
        'ubicacion': {},
        'precios': {
          '95': {'precio': '1300'},
          'A95': {'precio': '1205'},
        },
      });

      expect(stations, hasLength(1));
      expect(stations.first.price, 1205);
    });

    test('mapea GLP y parafina (KE) cuando informan precio', () {
      final stations = GasStation.fromCneStation({
        'codigo': 'ab110101',
        'distribuidor': {'marca': 'COPEC'},
        'ubicacion': {},
        'precios': {
          'GLP': {'precio': '819'},
          'KE': {'precio': '900'},
        },
      });

      expect(stations, hasLength(2));
      expect(
        stations.firstWhere((s) => s.fuelType == FuelType.glp).price,
        819,
      );
      expect(
        stations.firstWhere((s) => s.fuelType == FuelType.kerosene).price,
        900,
      );
    });

    test('omite combustibles sin precio disponible', () {
      final stations = GasStation.fromCneStation({
        'codigo': 'ab110101',
        'distribuidor': {'marca': 'COPEC'},
        'ubicacion': {},
        'precios': {
          'GLP': {'precio': '819'},
        },
      });

      expect(stations, hasLength(1));
      expect(stations.first.fuelType, FuelType.glp);
    });

    test('marca "No informado" cuando el combustible se ofrece sin precio '
        'válido', () {
      final stations = GasStation.fromCneStation({
        'codigo': 'ab110101',
        'distribuidor': {'marca': 'COPEC'},
        'ubicacion': {},
        'precios': {
          'GLP': {'precio': ''},
        },
      });

      expect(stations, hasLength(1));
      final station = stations.first;
      expect(station.fuelType, FuelType.glp);
      expect(station.price, isNull);
      expect(station.formattedPrice, 'No informado');
    });

    test('usa valores por defecto cuando faltan datos', () {
      final stations = GasStation.fromCneStation({
        'codigo': 'x',
        'precios': {
          '95': {'precio': '1000'},
        },
      });

      expect(stations, hasLength(1));
      final station = stations.first;
      expect(station.name, 'Sin bandera');
      expect(station.address, '');
      expect(station.lastUpdated, 'sin fecha');
      expect(station.latitude, isNull);
      expect(station.longitude, isNull);
    });
  });

  group('GasStationListX', () {
    const cheap = GasStation(
      id: 'cheap',
      name: 'Cheap',
      address: '',
      distanceKm: 1,
      fuelType: FuelType.gas95,
      price: 1000,
      lastUpdated: '',
    );
    const expensive = GasStation(
      id: 'expensive',
      name: 'Expensive',
      address: '',
      distanceKm: 1,
      fuelType: FuelType.gas95,
      price: 2000,
      lastUpdated: '',
    );

    test('cheapestOrNull devuelve la estación más barata', () {
      expect([expensive, cheap].cheapestOrNull, cheap);
    });

    test('cheapestOrNull devuelve null para una lista vacía', () {
      expect(<GasStation>[].cheapestOrNull, isNull);
    });
  });
}
