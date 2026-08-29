const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getAppCheck} = require("firebase-admin/app-check");
const axios = require("axios");
const {createCneAuth} = require("./lib/cneAuth");
const {createAppCheckGuard} = require("./lib/appCheckGuard");

const cneEmail = defineSecret("CNE_EMAIL");
const cnePassword = defineSecret("CNE_PASSWORD");

const CNE_ESTACIONES_URL = "https://api.cne.cl/api/v4/estaciones";

// La base de datos se llama "preciobencina" (no "(default)").
const FIRESTORE_DATABASE = "preciobencina";

initializeApp();

const cneAuth = createCneAuth({
  db: getFirestore(FIRESTORE_DATABASE),
  axiosClient: axios,
  getCredentials: () => ({email: cneEmail.value(), password: cnePassword.value()}),
});

// IMPORTANTE: `enforce: false` hasta que la app se distribuya por Google
// Play. El proveedor Play Integrity solo emite tokens para copias
// instaladas DESDE Google Play; en un APK cargado a mano (`adb install`,
// o pasado por archivo) la atestación falla siempre con:
//
//   [firebase_app_check/unknown] code: 403 body: App attestation failed
//
// (verificado en dispositivo real el 2026-08-29). O sea que activar
// `enforce: true` ahora dejaría la app sin datos para cualquiera que la
// pruebe fuera de Play, incluido el desarrollador.
//
// TODO: cambiar a `enforce: true` recién cuando (1) la app esté publicada
// en algún track de Play (interno/cerrado sirve) y (2) los logs de esta
// función muestren que los pedidos reales llegan con token válido, sin
// "pedido sin cabecera". En `false` no bloquea a nadie: solo registra.
const requireValidAppCheck = createAppCheckGuard({
  appCheck: getAppCheck(),
  enforce: false,
});

/**
 * BFF: entrega el listado de estaciones de la CNE sin exponer ninguna
 * credencial al cliente. El token se obtiene y renueva automáticamente del
 * lado del servidor (login con CNE_EMAIL/CNE_PASSWORD, cacheado en
 * Firestore).
 *
 * Exige un token de App Check válido (ver `lib/appCheckGuard.js`) para que
 * solo la app real pueda llamar a este endpoint, no un script cualquiera
 * que encuentre la URL.
 */
exports.obtenerEstacionesBencina = onRequest(
    {
      region: "southamerica-east1",
      secrets: [cneEmail, cnePassword],
      // La app móvil no envía cabecera Origin, así que no necesita CORS.
      // Desactivado para que sitios web de terceros no puedan leer la
      // respuesta desde el navegador del visitante (evita "hotlinking").
      cors: false,
    },
    async (req, res) => {
      if (!(await requireValidAppCheck(req, res))) return;

      try {
        let token = await cneAuth.getValidToken();

        let response;
        try {
          response = await axios.get(CNE_ESTACIONES_URL, {
            headers: {Authorization: `Bearer ${token}`},
            timeout: 30000,
          });
        } catch (error) {
          if (error.response && error.response.status === 401) {
            token = await cneAuth.loginAndCacheToken();
            response = await axios.get(CNE_ESTACIONES_URL, {
              headers: {Authorization: `Bearer ${token}`},
              timeout: 30000,
            });
          } else {
            throw error;
          }
        }

        res.status(200).json(response.data);
      } catch (error) {
        console.error("Error consultando la API de la CNE:", error.message);
        res.status(500).json({
          error: "No se pudo obtener el listado de estaciones de la CNE",
        });
      }
    },
);
