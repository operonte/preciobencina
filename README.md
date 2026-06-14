# preciobencina

App para comparar precios de combustible en Chile usando datos de la API
"Combustible Vehicular" de la CNE (api.cne.cl).

## Datos en vivo de la CNE

La app necesita un token Bearer de la CNE para obtener precios reales. Este
token se incluye **al momento de compilar**, no lo pide cada usuario.

1. Obtén un token en [api.cne.cl](https://api.cne.cl) (apidocs.cne.cl ->
   "Login usuario para obtener Token").
2. Compila/corre la app pasando el token con `--dart-define`:

   ```bash
   flutter run --dart-define=CNE_API_TOKEN=tu_token
   flutter build apk --dart-define=CNE_API_TOKEN=tu_token
   flutter build appbundle --dart-define=CNE_API_TOKEN=tu_token
   ```

3. **Importante**: usa siempre este flag al generar un build de release; sin
   él la app cae a datos de ejemplo (mock). El token nunca debe escribirse en
   el código fuente ni subirse a un repositorio.

Si no hay datos en vivo (sin token, sin red, o la API falla), la app usa la
última caché local guardada o, en su defecto, datos de ejemplo.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
