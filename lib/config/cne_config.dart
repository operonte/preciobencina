/// Configuración de acceso a la API "Combustible Vehicular" de la CNE
/// (api.cne.cl), usada por la app "Bencina en Línea".
///
/// Para obtener tu propio token:
/// 1. Crea una cuenta en https://api.cne.cl
/// 2. Usa el endpoint "Login usuario para obtener Token" (apidocs.cne.cl)
///    con tu correo y contraseña para obtener un token Bearer
///
/// El token NO debe quedar escrito en el código ni subirse a un repositorio
/// público. Pásalo en tiempo de build, por ejemplo:
///
///   flutter run --dart-define=CNE_API_TOKEN=tu_token
///   flutter build apk --dart-define=CNE_API_TOKEN=tu_token
class CneConfig {
  CneConfig._();

  static const apiToken = String.fromEnvironment('CNE_API_TOKEN');

  static const baseUrl = 'https://api.cne.cl/api/v4';
}
