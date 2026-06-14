import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/gas_station.dart';

/// Ruta del set de datos real de estaciones (snapshot de la API de la CNE)
/// incluido con la app, para que funcione con datos reales desde el primer
/// uso, incluso sin conexión a la API en vivo.
const _assetPath = 'assets/data/estaciones.json';

/// Carga el snapshot de estaciones incluido en la app.
///
/// Se usa cuando no hay datos en vivo de la CNE ni caché local: así la app
/// siempre muestra bencineras reales (con su precio en la fecha del
/// snapshot) en vez de un puñado de datos inventados.
Future<List<GasStation>> loadBundledStations({AssetBundle? bundle}) async {
  final raw = await (bundle ?? rootBundle).loadString(_assetPath);
  final rows = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  return rows.expand(GasStation.fromCneStation).toList();
}
