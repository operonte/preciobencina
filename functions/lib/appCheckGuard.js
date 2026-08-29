const APP_CHECK_HEADER = "X-Firebase-AppCheck";

/**
 * Crea un verificador de App Check para funciones `onRequest`.
 *
 * A diferencia de las "callable functions", `onRequest` no soporta la
 * opción `enforceAppCheck` (queda explícitamente excluida de sus opciones
 * en firebase-functions v2: `HttpsOptions` es `Omit<GlobalOptions,
 * "enforceAppCheck">`), así que hay que verificar el token a mano.
 *
 * Sin esto, cualquiera que encuentre la URL del BFF (está en texto plano
 * en el cliente, es trivial de extraer) puede llamarla directamente sin
 * pasar por la app, sin límite. Cada uno de esos pedidos se reenvía a la
 * CNE con la cuenta compartida del proyecto, así que un abuso externo
 * puede terminar bloqueando esa cuenta para todos los usuarios reales.
 *
 * @param {object} deps Dependencias inyectadas (para poder testear sin
 *   tocar el servicio real de App Check).
 * @param {{verifyToken: function(string): Promise<unknown>}} deps.appCheck
 *   Instancia de `AppCheck` (normalmente `getAppCheck()` de
 *   `firebase-admin/app-check`).
 * @param {boolean} [deps.enforce] Si es `false`, no bloquea ningún pedido:
 *   solo registra en los logs si el token vino y si es válido. Útil para
 *   confirmar en producción, con tráfico real, que los pedidos legítimos
 *   sí están mandando un token válido antes de empezar a rechazar los que
 *   no lo tengan. Por defecto `true` (si no se pasa, exige el token).
 * @return {function(import('express').Request, import('express').Response): Promise<boolean>}
 *   Función a llamar al inicio del handler: devuelve `true` si el pedido
 *   puede continuar, o `false` si ya respondió 401 y hay que cortar ahí.
 */
function createAppCheckGuard({appCheck, enforce = true}) {
  return async function requireValidAppCheck(req, res) {
    const token = req.header(APP_CHECK_HEADER);
    if (!token) {
      console.warn("App Check: pedido sin cabecera X-Firebase-AppCheck");
      if (!enforce) return true;
      res.status(401).json({error: "Falta la verificación de App Check"});
      return false;
    }

    try {
      await appCheck.verifyToken(token);
      return true;
    } catch (error) {
      console.warn("App Check: token inválido:", error.message);
      if (!enforce) return true;
      res.status(401).json({error: "Verificación de App Check inválida"});
      return false;
    }
  };
}

module.exports = {createAppCheckGuard, APP_CHECK_HEADER};
