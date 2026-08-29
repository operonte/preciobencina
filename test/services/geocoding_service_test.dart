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
        final result = await service.search('Providencia');

        expect(result.failed, isFalse);
        expect(result.suggestions, hasLength(1));
        expect(result.suggestions.first.label, 'Providencia, Santiago, Chile');
        expect(result.suggestions.first.latitude, -33.4309);
        expect(result.suggestions.first.longitude, -70.6256);
      },
    );

    test(
      'devuelve lista vacía para textos muy cortos, sin marcar error',
      () async {
        final client = MockClient((request) async {
          fail('No debería llamar a la API con texto corto');
        });

        final service = GeocodingService(client: client);
        final result = await service.search('ab');

        expect(result.suggestions, isEmpty);
        expect(result.failed, isFalse);
      },
    );

    test('distingue una búsqueda sin coincidencias de una que falló', () async {
      final client = MockClient(
        (request) async => http.Response(jsonEncode([]), 200),
      );

      final service = GeocodingService(client: client);
      final result = await service.search('xyzxyzxyz');

      expect(result.suggestions, isEmpty);
      expect(result.failed, isFalse);
    });

    test(
      'marca la búsqueda como fallida si la API responde con error',
      () async {
        final client = MockClient((request) async => http.Response('', 500));

        final service = GeocodingService(client: client);
        final result = await service.search('Providencia');

        expect(result.suggestions, isEmpty);
        expect(result.failed, isTrue);
      },
    );

    test('marca la búsqueda como fallida si no hay conexión', () async {
      final client = MockClient(
        (request) async => throw const SocketExceptionStub(),
      );

      final service = GeocodingService(client: client);
      final result = await service.search('Providencia');

      expect(result.suggestions, isEmpty);
      expect(result.failed, isTrue);
    });
  });
}

/// Sustituto liviano de `SocketException` para no depender de `dart:io` en
/// el test (que corre también en plataformas donde no está disponible).
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
