/// Configuración de acceso al backend (BFF) de PrecioBencina.
///
/// La app NUNCA llama directamente a la API de la CNE ni maneja tokens: todo
/// eso vive en Firebase Cloud Functions (`functions/index.js`). Aquí solo se
/// indica la URL pública de esa función.
///
/// El valor por defecto apunta al backend desplegado, así la app funciona
/// "de fábrica" sin pasos extra al compilar. Se puede sobrescribir (por
/// ejemplo para apuntar a un backend de pruebas) con:
///
///   flutter run --dart-define=BFF_BASE_URL=https://otra-url
class CneConfig {
  CneConfig._();

  /// URL base de la función `obtenerEstacionesBencina`. Si está vacío, la
  /// app usa el snapshot de estaciones incluido (ver [DataSource.bundled]).
  static const bffBaseUrl = String.fromEnvironment(
    'BFF_BASE_URL',
    defaultValue: 'https://obtenerestacionesbencina-gc3aqniswq-rj.a.run.app',
  );
}
