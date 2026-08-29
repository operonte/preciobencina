import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:preciobencina/services/cne_fuel_price_service.dart';

void main() {
  group('CneFuelPriceService', () {
    test(
      'devuelve el listado de estaciones cuando el backend responde 200',
      () async {
        final client = MockClient((request) async {
          expect(request.url.path, endsWith('/obtenerEstacionesBencina'));
          return http.Response(
            jsonEncode([
              {'codigo': 'ab110101', 'precios': {}},
            ]),
            200,
          );
        });

        final service = CneFuelPriceService(client: client);
        final rows = await service.fetchStationPrices();

        expect(rows, hasLength(1));
        expect(rows.first['codigo'], 'ab110101');
      },
    );

    test('lanza CneApiException si el backend responde con error', () async {
      final client = MockClient((request) async => http.Response('', 500));

      final service = CneFuelPriceService(client: client);

      expect(
        () => service.fetchStationPrices(),
        throwsA(isA<CneApiException>()),
      );
    });

    test('lanza CneApiException si la respuesta no es JSON válido', () async {
      final client = MockClient(
        (request) async => http.Response('no es json', 200),
      );

      final service = CneFuelPriceService(client: client);

      expect(
        () => service.fetchStationPrices(),
        throwsA(isA<CneApiException>()),
      );
    });

    test('lanza CneApiException si la conexión falla', () async {
      final client = MockClient((request) async => throw Exception('sin red'));

      final service = CneFuelPriceService(client: client);

      expect(
        () => service.fetchStationPrices(),
        throwsA(isA<CneApiException>()),
      );
    });

    test(
      'adjunta el token de App Check como cabecera cuando está disponible',
      () async {
        final client = MockClient((request) async {
          expect(request.headers['X-Firebase-AppCheck'], 'token-de-prueba');
          return http.Response(jsonEncode([]), 200);
        });

        final service = CneFuelPriceService(
          client: client,
          appCheckToken: () async => 'token-de-prueba',
        );

        await service.fetchStationPrices();
      },
    );

    test(
      'sigue el pedido sin la cabecera si no se pudo obtener el token '
      '(el backend la exige, así que esa falla la maneja la caché/snapshot)',
      () async {
        final client = MockClient((request) async {
          expect(request.headers.containsKey('X-Firebase-AppCheck'), isFalse);
          return http.Response(jsonEncode([]), 200);
        });

        final service = CneFuelPriceService(
          client: client,
          appCheckToken: () async => throw Exception('sin Play Services'),
        );

        await service.fetchStationPrices();
      },
    );
  });
}
