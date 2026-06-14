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

/// Cliente para la API "Combustible Vehicular" de la CNE (api.cne.cl),
/// que entrega el listado de estaciones de servicio con sus precios
/// vigentes por tipo de combustible.
class CneFuelPriceService {
  CneFuelPriceService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Obtiene el listado crudo de estaciones de servicio, cada una con su
  /// mapa `precios` (combustible -> info de precio).
  ///
  /// Lanza [CneApiException] si falta configurar `CNE_API_TOKEN` o si la
  /// respuesta de la API no es válida.
  Future<List<Map<String, dynamic>>> fetchStationPrices() async {
    if (CneConfig.apiToken.isEmpty) {
      throw CneApiException(
        'Falta configurar CNE_API_TOKEN. Obtén tu token en api.cne.cl y '
        'pásalo con --dart-define=CNE_API_TOKEN=tu_token',
      );
    }

    final uri = Uri.parse('${CneConfig.baseUrl}/estaciones');

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: {'Authorization': 'Bearer ${CneConfig.apiToken}'})
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw CneApiException('La API de la CNE no respondió a tiempo');
    } catch (error) {
      throw CneApiException('No se pudo conectar con la API de la CNE: $error');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw CneApiException('El token de la CNE es inválido o expiró');
    }
    if (response.statusCode != 200) {
      throw CneApiException(
        'La API de la CNE respondió con código ${response.statusCode}',
      );
    }

    List<dynamic> body;
    try {
      body = jsonDecode(response.body) as List<dynamic>;
    } catch (_) {
      throw CneApiException('Formato de respuesta inesperado de la CNE');
    }

    return body.cast<Map<String, dynamic>>();
  }
}
