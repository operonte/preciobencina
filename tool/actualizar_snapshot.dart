// Regenera `assets/data/estaciones.json`, el snapshot de estaciones que se
// incluye dentro del APK como último recurso cuando no hay datos en vivo
// ni caché reciente (ver `lib/repositories/gas_station_repository.dart`).
//
// Uso:
//   dart run tool/actualizar_snapshot.dart
//   dart run tool/actualizar_snapshot.dart --url=https://otro-bff
//
// Hay que correrlo antes de cada envío a Play Store para que el snapshot no
// quede desactualizado (ver CLAUDE.md, "Cadena de respaldo de datos").
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _defaultBffUrl =
    'https://obtenerestacionesbencina-gc3aqniswq-rj.a.run.app';

/// Campos de `ubicacion` que la app realmente usa (ver
/// `GasStation.fromCneStation`). El resto (región, comuna código, etc.) no
/// se usa y solo pesa en el APK.
const _ubicacionFields = ['direccion', 'nombre_comuna', 'latitud', 'longitud'];

/// Campos de cada entrada de `precios` que la app usa.
const _precioFields = ['precio', 'fecha_actualizacion', 'hora_actualizacion'];

Future<void> main(List<String> args) async {
  final urlArg = args.firstWhere(
    (a) => a.startsWith('--url='),
    orElse: () => '--url=$_defaultBffUrl',
  );
  final baseUrl = urlArg.substring('--url='.length);
  final uri = Uri.parse('$baseUrl/obtenerEstacionesBencina');

  stdout.writeln('Consultando $uri ...');
  final http.Response response;
  try {
    response = await http.get(uri).timeout(const Duration(seconds: 60));
  } catch (error) {
    stderr.writeln('No se pudo conectar al backend: $error');
    exit(1);
  }

  if (response.statusCode != 200) {
    stderr.writeln('El backend respondió ${response.statusCode}');
    exit(1);
  }

  final raw = jsonDecode(response.body) as List<dynamic>;
  if (raw.isEmpty) {
    stderr.writeln(
      'El backend devolvió una lista vacía; no se actualiza el snapshot.',
    );
    exit(1);
  }

  final trimmed = raw.cast<Map<String, dynamic>>().map(_trimStation).toList();

  final assetFile = File('assets/data/estaciones.json');
  await assetFile.writeAsString(jsonEncode(trimmed));

  final generatedAt = DateTime.now().toUtc();
  final metaFile = File('assets/data/estaciones_meta.json');
  await metaFile.writeAsString(
    jsonEncode({
      'generado_en': generatedAt.toIso8601String(),
      'total_estaciones': trimmed.length,
      'fuente': 'API pública de la CNE (https://api.cne.cl), vía BFF propio',
    }),
  );

  stdout.writeln(
    'Listo: ${trimmed.length} estaciones guardadas en ${assetFile.path} '
    '(${await assetFile.length()} bytes), generado ${generatedAt.toIso8601String()}.',
  );
}

/// Se queda solo con los campos que la app realmente lee, para no incluir
/// en el APK datos que nunca se usan (servicios, métodos de pago, horarios,
/// etc.).
Map<String, dynamic> _trimStation(Map<String, dynamic> station) {
  final ubicacionRaw =
      station['ubicacion'] as Map<String, dynamic>? ?? const {};
  final preciosRaw = station['precios'] as Map<String, dynamic>? ?? const {};

  return {
    'codigo': station['codigo'],
    'distribuidor': {'marca': (station['distribuidor'] as Map?)?['marca']},
    'ubicacion': {
      for (final field in _ubicacionFields)
        if (ubicacionRaw.containsKey(field)) field: ubicacionRaw[field],
    },
    'precios': {
      for (final entry in preciosRaw.entries)
        if (entry.value is Map<String, dynamic>)
          entry.key: {
            for (final field in _precioFields)
              if ((entry.value as Map<String, dynamic>).containsKey(field))
                field: (entry.value as Map<String, dynamic>)[field],
          },
    },
  };
}
