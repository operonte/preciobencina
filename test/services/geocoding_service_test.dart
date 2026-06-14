import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:preciobencina/services/geocoding_service.dart';

void main() {
  group('GeocodingService', () {
    test(
      'devuelve sugerencias a partir de la respuesta de Nominatim',
      () async {
        final client = MockClient((request) async {
          expect(request.url.queryParameters['q'], 'Providencia');
          return http.Response(
            jsonEncode([
              {
                'display_name': 'Providencia, Santiago, Chile',
                'lat': '-33.4309',
                'lon': '-70.6256',
              },
            ]),
            200,
          );
        });

        final service = GeocodingService(client: client);
        final results = await service.search('Providencia');

        expect(results, hasLength(1));
        expect(results.first.label, 'Providencia, Santiago, Chile');
        expect(results.first.latitude, -33.4309);
        expect(results.first.longitude, -70.6256);
      },
    );

    test('devuelve lista vacía para textos muy cortos', () async {
      final client = MockClient((request) async {
        fail('No debería llamar a la API con texto corto');
      });

      final service = GeocodingService(client: client);
      final results = await service.search('ab');

      expect(results, isEmpty);
    });

    test('devuelve lista vacía si la API falla', () async {
      final client = MockClient((request) async => http.Response('', 500));

      final service = GeocodingService(client: client);
      final results = await service.search('Providencia');

      expect(results, isEmpty);
    });
  });
}
