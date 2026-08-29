import 'dart:async';
import 'dart:convert';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:http/http.dart' as http;

import '../config/cne_config.dart';

/// Tiempo máximo de espera por la respuesta de la CNE. La consulta trae el
/// listado completo de estaciones a nivel nacional, por lo que puede tardar
/// varios segundos.
const _requestTimeout = Duration(seconds: 30);

/// Cabecera que el backend exige para aceptar el pedido (ver
/// `functions/lib/appCheckGuard.js`): prueba que viene de una copia
/// legítima de la app y no de un script que encontró la URL del BFF.
const _appCheckHeader = 'X-Firebase-AppCheck';

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
  CneFuelPriceService({http.Client? client, this._appCheckToken})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Provee el token de App Check a adjuntar en cada pedido. Inyectable
  /// para tests; en producción es `null`, y [_headers] recurre a
  /// [FirebaseAppCheck.instance.getToken] recién al pedirlo (no en el
  /// constructor: acceder a `FirebaseAppCheck.instance` antes de tiempo
  /// lanza si Firebase no está inicializado, como en varios tests que usan
  /// un fake que ni siquiera llama a [_headers]).
  final Future<String?> Function()? _appCheckToken;

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
      response = await _client
          .get(uri, headers: await _headers())
          .timeout(_requestTimeout);
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

  /// Cabeceras del pedido: incluye el token de App Check si se pudo
  /// obtener. Si falla (Firebase no se inicializó, dispositivo sin Play
  /// Services, etc.) se sigue sin la cabecera; el backend rechazará el
  /// pedido con 401 y esa falla ya la maneja el resto de la cadena de
  /// respaldo (caché, snapshot) en [GasStationRepository].
  Future<Map<String, String>> _headers() async {
    try {
      final getToken = _appCheckToken ?? FirebaseAppCheck.instance.getToken;
      final token = await getToken();
      if (token == null) return const {};
      return {_appCheckHeader: token};
    } catch (error, stack) {
      _reportAppCheckFailure(error, stack);
      return const {};
    }
  }

  /// Reporta a Crashlytics que no se pudo obtener el token de App Check,
  /// para ver la causa real (por ejemplo en producción, sin depender de
  /// conectar el teléfono por USB) en vez de solo saber que el backend
  /// rechazó el pedido por faltar la cabecera. Nunca deja que un fallo en
  /// el reporte mismo se propague (p. ej. en tests, sin Firebase
  /// inicializado, o si Crashlytics no llegó a activarse).
  void _reportAppCheckFailure(Object error, StackTrace stack) {
    try {
      unawaited(
        FirebaseCrashlytics.instance
            .recordError(
              error,
              stack,
              reason: 'Fallo al obtener el token de App Check',
              fatal: false,
            )
            .catchError((_) {}),
      );
    } catch (_) {
      // Ni Crashlytics está disponible (Firebase no inicializado, como en
      // los tests que no lo montan): no hay dónde reportar, se ignora.
    }
  }
}
