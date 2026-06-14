const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const axios = require("axios");

const cneEmail = defineSecret("CNE_EMAIL");
const cnePassword = defineSecret("CNE_PASSWORD");

const CNE_LOGIN_URL = "https://api.cne.cl/api/login";
const CNE_ESTACIONES_URL = "https://api.cne.cl/api/v4/estaciones";

// La base de datos se llama "preciobencina" (no "(default)").
const FIRESTORE_DATABASE = "preciobencina";
const REFRESH_BUFFER_MS = 60_000;

initializeApp();

/**
 * Decodifica el campo "exp" (segundos epoch) de un JWT, sin verificar firma:
 * solo lo necesitamos para saber cuándo pedir uno nuevo.
 * @param {string} token Token JWT recibido de la CNE.
 * @return {number} Marca de tiempo (ms) de expiración del token.
 */
function decodeJwtExpiry(token) {
  const payload = JSON.parse(
      Buffer.from(token.split(".")[1], "base64url").toString("utf8"),
  );
  return payload.exp * 1000;
}

/**
 * Inicia sesión en la API de la CNE y guarda el token nuevo en Firestore.
 * @return {Promise<string>} Token Bearer recién obtenido.
 */
async function loginAndCacheToken() {
  const response = await axios.post(CNE_LOGIN_URL, {
    email: cneEmail.value(),
    password: cnePassword.value(),
  });
  const token = response.data.token;
  const expiresAt = decodeJwtExpiry(token);

  const db = getFirestore(FIRESTORE_DATABASE);
  await db.collection("cne_auth").doc("token").set({token, expiresAt});

  return token;
}

/**
 * Obtiene un token Bearer válido: reutiliza el guardado en Firestore si no
 * está por vencer, o inicia sesión de nuevo si falta o está vencido.
 * @return {Promise<string>} Token Bearer válido.
 */
async function getValidToken() {
  const db = getFirestore(FIRESTORE_DATABASE);
  const snap = await db.collection("cne_auth").doc("token").get();
  const cached = snap.data();

  if (cached && cached.expiresAt - Date.now() > REFRESH_BUFFER_MS) {
    return cached.token;
  }
  return loginAndCacheToken();
}

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
      cors: true,
    },
    async (req, res) => {
      try {
        let token = await getValidToken();

        let response;
        try {
          response = await axios.get(CNE_ESTACIONES_URL, {
            headers: {Authorization: `Bearer ${token}`},
            timeout: 30000,
          });
        } catch (error) {
          if (error.response && error.response.status === 401) {
            token = await loginAndCacheToken();
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
