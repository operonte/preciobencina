# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

PrecioBencina es una app Flutter para comparar precios de combustible en Chile con datos en vivo de la CNE (`api.cne.cl`). Versión actual `1.3.1+8`. Targets Android e iOS. Todo el código, los comentarios y la UI están en español.

**Estado en Play Store:** la app fue retirada el 19 de julio de 2026 por la política de afirmaciones engañosas (fuentes de datos no declaradas explícitamente en la ficha). La versión `1.3.1+8` corrige esto: declara las 5 fuentes reales (CNE, OpenStreetMap, la app de mapas del dispositivo, y los dos modos sin conexión) tanto en la ficha de Play Store como dentro de la app, y elimina los datos de ejemplo inventados que antes existían como último fallback (`lib/data/mock_stations.dart`, ya no existe). Pendiente reenviar desde Play Console.

El repo tiene dos mitades:

- **App Flutter** (`lib/`, `test/`) — el cliente.
- **BFF en Firebase Cloud Functions** (`functions/`) — el backend que oculta las credenciales de la CNE.

## Commands

```bash
flutter pub get                        # dependencias
flutter run                            # correr la app
flutter analyze                        # análisis estático (flutter_lints)
flutter test                           # tests unitarios (test/)
flutter test test/models/gas_station_test.dart    # un archivo
flutter build appbundle --release      # AAB para Play Store
flutter build apk --release            # APK

cd functions && npm test               # tests del BFF (node --test)
firebase deploy --only functions       # desplegar el BFF
firebase deploy --only hosting         # desplegar public/ (privacidad, términos)
```

Para apuntar la app a otro backend: `flutter run --dart-define=BFF_BASE_URL=https://otra-url`.

## Reglas duras

Tres cosas que **nunca** deben romperse:

1. **La app jamás maneja tokens ni credenciales de la CNE.** Llama al BFF con un GET sin cabeceras de autenticación. Cualquier propuesta de "simplificar" metiendo el token en el cliente está descartada: el token de la CNE es personal y quedaría expuesto en el APK.
2. **La base de datos de Firestore se llama `preciobencina`, nunca `(default)`.** Está así en `firebase.json` y en `functions/index.js` (`FIRESTORE_DATABASE`).
3. **Cero configuración para el usuario final.** No hay ninguna UI para pegar tokens, URLs ni claves. La app funciona de fábrica.

## Architecture

### App (`lib/`)

- `config/cne_config.dart` — solo la URL del BFF (`BFF_BASE_URL`, con default al backend desplegado).
- `models/` — `gas_station.dart` (incluye `FuelType`), `place_suggestion.dart`.
- `repositories/gas_station_repository.dart` — punto único de acceso a datos.
- `services/` — `cne_fuel_price_service.dart` (cliente HTTP del BFF), más geocoding, ubicación y favoritos.
- `screens/`, `widgets/`, `theme/` — UI.
- `data/bundled_stations.dart` — carga `assets/data/estaciones.json` (snapshot real, ~1,2 MB) y su metadata `estaciones_meta.json` (fecha de generación). Se regenera con `dart run tool/actualizar_snapshot.dart`; hay que correrlo antes de cada envío a Play Store para que no quede desactualizado.

### Cadena de respaldo de datos

`GasStationRepository.fetchNearbyStations()` degrada en orden. El origen viaja en `GasStationsResult.source` (`enum DataSource`) para que la UI pueda avisar, con la fecha del dato cuando no es de ahora:

`live` (CNE ahora) → `cached` (última respuesta guardada en `SharedPreferences`, descartada si tiene más de 7 días) → `bundled` (snapshot incluido en el APK) → `unavailable` (no se pudo obtener nada; la UI ofrece reintentar).

No hay un cuarto nivel de datos inventados: existió (`lib/data/mock_stations.dart`) hasta que Google Play rechazó la app por "afirmaciones engañosas" — mostraba precios ficticios atribuidos a marcas reales (Copec, Shell) bajo la misma UI que los datos oficiales. Se eliminó por completo; no debe reintroducirse.

### Límite de 20 estaciones por combustible

`_maxStationsPerFuel = 20`, y se cuenta **por combustible, no de forma global**. La CNE devuelve ~2000 estaciones nacionales en cada consulta; quedarse solo con las cercanas mantiene livianos la app, el mapa y la caché.

Se cuenta por combustible a propósito: la parafina y el GLP los ofrecen pocas estaciones, así que un tope global —dominado por las bencineras comunes— dejaría al usuario con dos o tres resultados al filtrar por ellos. Contándolos por separado, cada combustible llega a sus ~20 más cercanas aunque queden más lejos.

### BFF (`functions/`)

`obtenerEstacionesBencina` (región `southamerica-east1`) es una `onRequest` v2 que:

1. Pide un token válido a `lib/cneAuth.js`, que lo reutiliza desde Firestore (colección `cne_auth`, doc `token`) mientras no esté por vencer, o hace login de nuevo con `CNE_EMAIL`/`CNE_PASSWORD` desde Secret Manager. El token de la CNE dura 1 hora y se renueva solo; el vencimiento sale de decodificar el `exp` del JWT (sin verificar firma — solo se necesita la fecha).
2. Llama a `https://api.cne.cl/api/v4/estaciones` y devuelve la respuesta tal cual.
3. Si la CNE responde 401, fuerza un login nuevo y reintenta una vez.

`cors: false` es intencional: la app móvil no envía cabecera `Origin`, así que no lo necesita, y desactivarlo evita que sitios de terceros lean la respuesta desde el navegador del visitante (hotlinking).

`cneAuth.js` recibe sus dependencias inyectadas (Firestore, cliente HTTP, credenciales) para poder testearlo sin tocar servicios reales — ver `functions/test/cneAuth.test.js`.

### Secretos

Nunca se commitean. Se cargan con `printf` para no dejar un salto de línea al final:

```bash
printf '%s' 'correo@ejemplo.com' | firebase functions:secrets:set CNE_EMAIL --data-file -
```

## Play Store

`play_store/` tiene la ficha, los textos y las capturas. `public/` tiene `privacidad.html` y `terminos.html`, servidas por Firebase Hosting con `cleanUrls: true` (o sea, `/privacidad` sin `.html`).

La v1.3.0+6 fue rechazada por faltar el link a la fuente de datos (CNE); se agregó el link y se reenvió como `1.3.0+7`, pero Google la rechazó de nuevo (política de afirmaciones engañosas) porque la ficha decía "todos los datos vienen de la CNE" en términos absolutos sin declarar las otras fuentes que la app sí usa (OpenStreetMap para mapa y búsqueda, la app de mapas del dispositivo para rutas, caché local y snapshot incluido para el modo sin conexión). La `1.3.1+8` declara las cinco fuentes explícitamente en la ficha y en la app — ver `play_store/textos/ficha_play_store.md`. Cualquier ficha nueva debe enumerar **todas** las fuentes que la app usa, no solo la CNE, y usar solo URLs que respondan (verificar con `curl` antes de enviar: `parafinaenlinea.gob.cl` y `energiaabierta.cl` estaban caídas en agosto 2026).

La firma de release usa keystore propio (`preciobencina-release.jks`), fuera del control de versiones.

# Compact instructions

Al compactar, prioriza: cambios de código pendientes, resultados de `flutter analyze` y `flutter test`, y decisiones tomadas sobre la arquitectura del BFF. Descarta listados de archivos y salidas largas de build ya resueltas.
