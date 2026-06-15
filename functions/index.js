const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const axios = require("axios");
const {createCneAuth} = require("./lib/cneAuth");

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

/**
 * BFF: entrega el listado de estaciones de la CNE sin exponer ninguna
 * credencial al cliente. El token se obtiene y renueva automáticamente del
 * lado del servidor (login con CNE_EMAIL/CNE_PASSWORD, cacheado en
 * Firestore).
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
