# PrecioBencina — Material para la ficha de Google Play (prueba cerrada)

Todo el texto está listo para copiar y pegar directo en Play Console. Los
límites de caracteres de cada campo están indicados entre paréntesis.

---

## 1. Datos básicos

**Nombre de la app** (máx. 30 caracteres)

```
PrecioBencina
```

**Descripción breve** (máx. 80 caracteres — 72 usados)

```
Encuentra la bencina más barata cerca de ti, con datos en vivo de la CNE
```

**Categoría sugerida:** Mapas y navegación
(alternativas razonables: Herramientas, o Estilo de vida — pero "Mapas y
navegación" es la que mejor describe el uso principal: encontrar bencineras
cercanas en un mapa)

**Etiqueta de precio:** Gratis

**Correo de contacto:** cristian.bravo.droguett@gmail.com

**Sitio web:** https://cristianbravo-dev.web.app/project/preciobencina

**Política de privacidad (URL obligatoria):** https://preciobencina.web.app/privacidad

**Términos de uso (opcional, referencia interna):** https://preciobencina.web.app/terminos

---

## 2. Descripción completa (máx. 4000 caracteres)

Play Store no interpreta markdown en este campo: el texto se pega tal cual,
sin asteriscos ni guiones de separación. Usa mayúsculas para los títulos de
sección, igual que el resto de la ficha.

```
PrecioBencina es un proyecto independiente. NO representa, no está asociado, vinculado, afiliado ni patrocinado por la Comisión Nacional de Energía (CNE), el Ministerio de Energía, el Gobierno de Chile ni ningún otro organismo público chileno.

FUENTES DE INFORMACIÓN

1) Precios y estaciones de servicio: Comisión Nacional de Energía (CNE), Gobierno de Chile. Se obtienen de su API pública de acceso libre. Puedes verificarlos tú mismo en:
- Comisión Nacional de Energía: https://www.cne.cl
- Ministerio de Energía: https://www.energia.gob.cl
- Portal de datos y API de la CNE: https://api.cne.cl
- Bencina en Línea (bencinas, diésel, parafina): https://www.bencinaenlinea.cl
- Gas en Línea (GLP): https://gasenlinea.gob.cl

2) Mapas y búsqueda de direcciones y comunas: OpenStreetMap, © colaboradores de OpenStreetMap (openstreetmap.org/copyright).

3) Cómo llegar: se abre la aplicación de mapas ya instalada en tu teléfono (por ejemplo Google Maps). PrecioBencina no calcula rutas.

4) Modo sin conexión: si no hay internet, la app muestra la última consulta a la CNE guardada en tu propio teléfono, o una copia de respaldo de datos de la CNE incluida con la aplicación. En ambos casos verás un aviso en pantalla indicando el origen y la fecha de esos precios.

La app consulta la API de la CNE a través de un servidor propio que solo reenvía la respuesta, sin alterar los datos. PrecioBencina no genera, no estima ni modifica precios: únicamente muestra lo que cada estación declaró a la CNE.

¿Cansado de pagar más de la cuenta por bencina? PrecioBencina te muestra al instante cuál es la estación de servicio más barata cerca de ti, con precios reales de la CNE.

Sin registro, sin cuentas, sin letra chica: abres la app y ves los precios.

QUÉ PUEDES HACER

• Ver en un mapa las bencineras cercanas a tu ubicación, con la más barata destacada al instante.
• Comparar precios de Gasolina 93, 95, 97, Diésel, Parafina y GLP entre distintas estaciones y marcas (Copec, Shell, Petrobras, Aramco, Gasco, Lipigas, Abastible, y más).
• Buscar por dirección, comuna o lugar, para revisar precios cerca de donde vas a estar (no solo donde estás ahora).
• Ordenar los resultados por precio o por distancia, según lo que te importe más en el momento.
• Guardar tus estaciones favoritas para encontrarlas más rápido la próxima vez.
• Ver el detalle de cada estación: dirección, distancia y hace cuánto se actualizó el precio.

DATOS OFICIALES Y ACTUALIZADOS

Los precios que ves provienen de la API pública de la CNE, el organismo del Estado chileno que regula y publica la información de combustibles. Si un precio no coincide con lo que ves en la calle, generalmente es porque la estación aún no ha reportado el cambio (tiene hasta 2 horas para hacerlo).

TU PRIVACIDAD PRIMERO

PrecioBencina no pide registro ni cuenta de usuario. No recopilamos tu nombre, correo ni ningún dato que te identifique. Tu ubicación GPS se usa únicamente en tu propio teléfono para calcular qué estaciones tienes cerca, y nunca se envía a nuestros servidores.

PENSADA PARA CHILE

Esta app fue creada pensando en el día a día de los conductores en Chile: encontrar rápido dónde conviene cargar combustible, sin vueltas ni publicidad invasiva.

¿Tienes dudas, sugerencias o encontraste un error? Escríbenos, dentro de la app en la sección "Acerca de" hay un correo de contacto directo.
```

**Dos URLs a evitar**, verificadas al momento de escribir esto:
`parafinaenlinea.gob.cl` no resuelve por DNS y `energiaabierta.cl` no responde por
HTTPS. La política de Google exige fuentes "válidas y funcionales"; un link
muerto puede motivar un tercer rechazo. Las cinco URLs de arriba sí responden
(200). Nota que `energia.gob.cl` y `gasenlinea.gob.cl` son dominios `.gob.cl`
— el equivalente chileno del `.gov` que la política pide explícitamente para
EE. UU. y del `.go.jp` para Japón.

---

## 3. Notas de la versión / "Novedades" (máx. 500 caracteres)

```
Versión 1.3.1 (build 8)

- Se detallan todas las fuentes de datos de la app (CNE, OpenStreetMap) y se muestra la fuente oficial en cada pantalla, en cumplimiento de las políticas de Play Store.
- Cuando la app funciona sin conexión, ahora indica la fecha de los precios que muestra.
- Buscador, mapa interactivo y lista de bencineras con combustibles baratos cerca de ti.
- Consulta de Gasolina 93/95/97, Diésel, Parafina y GLP.
- Sin registro y sin publicidad invasiva.
```

**Por qué 1.3.1+8 y no solo 1.3.0+8:** hay cambios de comportamiento reales,
no solo de texto — ya no se muestran datos de ejemplo inventados en ningún
caso, y el modo sin conexión ahora expira la caché a los 7 días. Un
`versionCode` nuevo (el `+8`) es indispensable para que Google revise la
app de nuevo; el `1.3.1` en vez de `1.3.0` es simplemente para reflejar que
no es solo un rebuild del mismo código.

---

## 4. Recursos gráficos (en `play_store/`)

| Campo en Play Console                                   | Archivo                                          | Tamaño                 |
| ------------------------------------------------------- | ------------------------------------------------ | ---------------------- |
| Ícono de la app                                         | `icono/icono_512x512.png`                        | 512×512                |
| Gráfico de funciones (feature graphic)                  | `feature_graphic/feature_graphic_1024x500.png`   | 1024×500               |
| Capturas de pantalla del teléfono (subir en este orden) | `capturas/01_home_mapa.png` … `05_acerca_de.png` | 1080×1920 (5 imágenes) |

Las capturas son recreaciones fieles del diseño real de la app (mismos
colores, tipografía y componentes) hechas para verse bien en la ficha; no
son capturas tomadas de un emulador. Si prefieres capturas 100% reales,
puedo generarlas corriendo la app en un emulador Android cuando tengas uno
configurado — solo pídemelo.

---

## 5. Cuestionario de clasificación de contenido (IARC)

Play Console hace este cuestionario por categoría (Google lo pide para
todas las apps antes de publicar, incluida la prueba cerrada). Para
PrecioBencina, las respuestas son:

- Violencia: No
- Contenido sexual / desnudos: No
- Lenguaje soez: No
- Referencias a drogas, alcohol o tabaco: No
- Apuestas o simulación de apuestas: No
- Contenido generado por el usuario: No
- Comunicación entre usuarios / chat: No
- Comparte la ubicación del usuario con otros usuarios: No
- Compras dentro de la app: No
- Publicidad: No

Con estas respuestas el resultado esperado es la clasificación más baja
disponible en cada sistema regional (ej. PEGI 3 / Everyone / Clasificación
General "Todo público").

**Público objetivo:** la app no está dirigida a niños ni tiene contenido
infantil; al configurar el "público objetivo y contenido" en Play Console,
lo normal es no seleccionar rangos de edad infantiles (menores de 13) y
declarar que la app no está diseñada para niños (esto activa las reglas de
Google relacionadas con la Ley COPPA/Ley de EE.UU. para apps infantiles,
que no aplican aquí).

---

## 6. Formulario de seguridad de datos (Data safety)

Basado en lo que la app realmente hace (revisado en el código: uso de
`geolocator`, y los SDKs `firebase_analytics`, `firebase_crashlytics` y
`firebase_app_check` en `pubspec.yaml`):

**Ubicación**

- Ubicación aproximada: se recopila — Sí
- Ubicación precisa: se recopila — Sí (permiso `ACCESS_FINE_LOCATION`)
- ¿Se comparte con terceros?: No — se usa solo en el dispositivo para
  calcular distancias; nunca se envía a un servidor (propio ni de terceros)
- Finalidad: Funcionalidad de la app
- ¿Es obligatoria?: Opcional (el usuario puede buscar por dirección en vez
  de usar el GPS)
- Procesamiento: puede marcarse como "procesada de forma efímera" (no se
  almacena la ubicación del usuario; solo se guarda en caché la lista de
  estaciones ya con la distancia calculada)

**Datos de la app / diagnóstico (por Firebase Crashlytics + Analytics)**

- Informes de fallos (crash logs): se recopilan — Sí — se comparten con
  Google (Firebase) como proveedor de servicios — Finalidad: Diagnóstico /
  Analítica
- Interacciones con la app (eventos como qué pestaña se usa o qué
  combustible se filtra): se recopilan — Sí — se comparten con Google
  (Firebase) — Finalidad: Analítica
- Identificadores de dispositivo (ID de instancia de Firebase): se
  recopilan — Sí — Finalidad: Analítica / Diagnóstico

**Datos que la app NO recopila:** nombre, correo, teléfono, contactos,
fotos, archivos, historial de navegación, información financiera, salud,
mensajes.

**Cifrado en tránsito:** Sí (HTTPS/TLS en todas las conexiones, incluida la
llamada al backend propio y a Firebase).

**Eliminación de datos:** actualmente la app no ofrece un mecanismo propio
para solicitar borrado de los datos de Analytics/Crashlytics (son datos
técnicos, no asociados a una identidad); si Play Console pregunta por un
enlace o proceso de borrado, la opción honesta es indicar que no aplica o
dejarlo en blanco, ya que no se recopila ningún dato personal identificable.

> Nota: Play Console tiene un asistente que escanea las dependencias del
> proyecto y sugiere automáticamente varias de estas respuestas (verás un
> botón "Usar sugerencias del SDK" o similar al completar el formulario).
> Úsalo como segunda validación de lo anterior.

---

## 7. Prueba cerrada: lo que falta que definas tú

Estos puntos dependen de decisiones que solo tú puedes tomar, no pude
generarlos:

1. **Lista de testers**: correos electrónicos de las personas que probarán
   la app, o un Google Group ya creado con esos correos.
2. **Instrucciones para los testers** (opcional, texto libre en Play
   Console). Sugerencia lista para usar:
   ```
   ¡Gracias por probar PrecioBencina! Solo necesitas abrir la app y
   permitir el acceso a tu ubicación para ver las bencineras más cercanas.
   Si algo falla o el precio se ve raro, cuéntame por correo a
   cristian.bravo.droguett@gmail.com.
   ```
3. **Cuenta de Google Play Console**: si es una cuenta nueva, Google exige
   mantener la prueba cerrada con al menos 12 testers activos durante 14
   días continuos antes de poder pasar a producción.
