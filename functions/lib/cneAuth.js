const CNE_LOGIN_URL = "https://api.cne.cl/api/login";
const REFRESH_BUFFER_MS = 60_000;

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
 * Crea las funciones de autenticación contra la API de la CNE, con sus
 * dependencias (Firestore, cliente HTTP y credenciales) inyectadas para
 * poder probarlas sin tocar servicios reales.
 * @param {object} deps Dependencias inyectadas.
 * @param {object} deps.db Instancia de Firestore (colección "cne_auth").
 * @param {object} deps.axiosClient Cliente HTTP estilo axios.
 * @param {function(): {email: string, password: string}} deps.getCredentials
 *   Devuelve las credenciales de la CNE.
 * @return {{getValidToken: function(): Promise<string>,
 *   loginAndCacheToken: function(): Promise<string>}} Funciones de auth.
 */
function createCneAuth({db, axiosClient, getCredentials}) {
  /**
   * Inicia sesión en la API de la CNE y guarda el token nuevo en Firestore.
   * @return {Promise<string>} Token Bearer recién obtenido.
   */
  async function loginAndCacheToken() {
    const {email, password} = getCredentials();
    const response = await axiosClient.post(CNE_LOGIN_URL, {email, password});
    const token = response.data.token;
    const expiresAt = decodeJwtExpiry(token);

    await db.collection("cne_auth").doc("token").set({token, expiresAt});

    return token;
  }

  /**
   * Obtiene un token Bearer válido: reutiliza el guardado en Firestore si no
   * está por vencer, o inicia sesión de nuevo si falta o está vencido.
   * @return {Promise<string>} Token Bearer válido.
   */
  async function getValidToken() {
    const snap = await db.collection("cne_auth").doc("token").get();
    const cached = snap.data();

    if (cached && cached.expiresAt - Date.now() > REFRESH_BUFFER_MS) {
      return cached.token;
    }
    return loginAndCacheToken();
  }

  return {getValidToken, loginAndCacheToken};
}

module.exports = {decodeJwtExpiry, createCneAuth, CNE_LOGIN_URL, REFRESH_BUFFER_MS};
