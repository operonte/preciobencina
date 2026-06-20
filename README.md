# preciobencina

App para comparar precios de combustible en Chile usando datos de la API
"Combustible Vehicular" de la CNE (api.cne.cl).

## Datos en vivo (arquitectura BFF)

La app **nunca** maneja credenciales ni tokens de la CNE. En su lugar llama a
un backend propio (Firebase Cloud Functions, ver [`functions/`](functions/))
mediante una simple petición GET, sin headers de autenticación. La URL de ese
backend ya viene incluida por defecto en
[`lib/config/cne_config.dart`](lib/config/cne_config.dart), así que la app
funciona "de fábrica" con datos reales, sin pasos adicionales.

### Cómo funciona el backend

1. La función `obtenerEstacionesBencina` recibe la petición de la app.
2. Obtiene un token de la CNE válido: lo reutiliza desde Firestore (base de
   datos `preciobencina`) si no está por vencer, o inicia sesión de nuevo con
   `CNE_EMAIL`/`CNE_PASSWORD` (guardados en Secret Manager) si falta o
   expiró. El token de la CNE dura 1 hora, así que se renueva solo.
3. Llama a `https://api.cne.cl/api/v4/estaciones` con ese token y devuelve el
   resultado tal cual a la app.

### Desplegar tu propio backend (opcional)

1. Crea un proyecto de Firebase en plan Blaze, con Firestore habilitado en
   una base de datos llamada `preciobencina` (nunca `(default)`).
2. Guarda tus credenciales de [api.cne.cl](https://api.cne.cl) como secretos
   (usa `printf` para no incluir un salto de línea al final del valor):

   ```bash
   printf '%s' 'tu_correo@ejemplo.com' | firebase functions:secrets:set CNE_EMAIL --data-file -
   printf '%s' 'tu_contraseña' | firebase functions:secrets:set CNE_PASSWORD --data-file -
   ```

3. Despliega la función:

   ```bash
   firebase deploy --only functions
   ```

4. Compila la app apuntando a tu propia URL:

   ```bash
   flutter build apk --release --dart-define=BFF_BASE_URL=https://tu-funcion.run.app
   ```

Si no hay datos en vivo (sin red o si el backend falla), la app usa la última
caché local guardada o, en su defecto, el snapshot de estaciones incluido.

## Desarrollo

Proyecto Flutter. Para correrlo en local:

```bash
flutter pub get
flutter run
```

### Pruebas

```bash
flutter test                  # app (Dart)
npm --prefix functions test   # backend (Cloud Functions)
```
