import 'dart:convert';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart';

import '../models/gas_station.dart';

/// Ruta del set de datos real de estaciones (snapshot de la API de la CNE)
/// incluido con la app, para que funcione con datos reales desde el primer
/// uso, incluso sin conexión a la API en vivo. Se regenera con
/// `dart run tool/actualizar_snapshot.dart` (ver ese archivo).
const _assetPath = 'assets/data/estaciones.json';

/// Metadata del snapshot (fecha de generación), escrita por el mismo script.
const _metaAssetPath = 'assets/data/estaciones_meta.json';

/// Snapshot de estaciones más la fecha en que se generó, si se pudo leer.
typedef BundledStations = ({List<GasStation> stations, DateTime? generatedAt});

/// Carga el snapshot de estaciones incluido en la app.
///
/// Se usa cuando no hay datos en vivo de la CNE ni caché local reciente:
/// así la app siempre muestra bencineras reales (con su precio en la fecha
/// del snapshot, que la UI muestra explícitamente) en vez de quedarse sin
/// nada que mostrar.
Future<BundledStations> loadBundledStations({AssetBundle? bundle}) async {
  final assetBundle = bundle ?? rootBundle;
  final raw = await assetBundle.loadString(_assetPath);
  // El snapshot decodifica a miles de GasStation (una por combustible por
  // estación); se hace en un isolate aparte para no bloquear el hilo de UI
  // justo en el arranque sin conexión.
  final stations = await compute(_parseStations, raw);

  DateTime? generatedAt;
  try {
    final metaRaw = await assetBundle.loadString(_metaAssetPath);
    final meta = jsonDecode(metaRaw) as Map<String, dynamic>;
    generatedAt = DateTime.tryParse(meta['generado_en']?.toString() ?? '');
  } catch (_) {
    // Metadata opcional: si falta o no se puede leer, seguimos sin fecha.
  }

  return (stations: stations, generatedAt: generatedAt);
}

/// Decodifica el JSON del snapshot y lo expande a [GasStation]s. Se ejecuta
/// en un isolate aparte (ver [compute] en [loadBundledStations]), así que
/// debe ser una función top-level y no depender de estado externo.
List<GasStation> _parseStations(String raw) {
  final rows = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  return rows.expand(GasStation.fromCneStation).toList();
}
