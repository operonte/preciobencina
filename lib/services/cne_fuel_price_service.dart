import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/cne_config.dart';

/// Tiempo máximo de espera por la respuesta de la CNE. La consulta trae el
/// listado completo de estaciones a nivel nacional, por lo que puede tardar
/// varios segundos.
const _requestTimeout = Duration(seconds: 30);

/// Excepción lanzada cuando la API de la CNE no puede ser consultada
/// (falta token, error de red o respuesta inesperada).
class CneApiException implements Exception {
  CneApiException(this.message);

  final String message;

  @override
  String toString() => 'CneApiException: $message';
}

/// Cliente del backend (BFF) de PrecioBencina: obtiene el listado de
/// estaciones de servicio con sus precios vigentes sin que el cliente
/// maneje ningún token de la CNE (eso vive en `functions/index.js`).
class CneFuelPriceService {
  CneFuelPriceService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Obtiene el listado crudo de estaciones de servicio, cada una con su
  /// mapa `precios` (combustible -> info de precio).
  ///
  /// Lanza [CneApiException] si falta configurar `BFF_BASE_URL` o si la
  /// respuesta del backend no es válida.
  Future<List<Map<String, dynamic>>> fetchStationPrices() async {
    if (CneConfig.bffBaseUrl.isEmpty) {
      throw CneApiException('Falta configurar BFF_BASE_URL');
    }

    final uri = Uri.parse('${CneConfig.bffBaseUrl}/obtenerEstacionesBencina');

    http.Response response;
    try {
      response = await _client.get(uri).timeout(_requestTimeout);
    } on TimeoutException {
      throw CneApiException('El backend no respondió a tiempo');
    } catch (error) {
      throw CneApiException('No se pudo conectar con el backend: $error');
    }

    if (response.statusCode != 200) {
      throw CneApiException(
        'El backend respondió con código ${response.statusCode}',
      );
    }

    List<dynamic> body;
    try {
      body = jsonDecode(response.body) as List<dynamic>;
    } catch (_) {
      throw CneApiException('Formato de respuesta inesperado del backend');
    }

    return body.cast<Map<String, dynamic>>();
  }
}
