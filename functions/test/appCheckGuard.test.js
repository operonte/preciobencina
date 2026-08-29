const test = require("node:test");
const assert = require("node:assert");

const {createAppCheckGuard, APP_CHECK_HEADER} = require("../lib/appCheckGuard");

/**
 * Crea una respuesta Express falsa que registra el código y el cuerpo
 * enviados, para poder verificarlos en los tests.
 * @return {{res: object, sent: {status: ?number, body: ?object}}}
 */
function createFakeRes() {
  const sent = {status: null, body: null};
  const res = {
    status(code) {
      sent.status = code;
      return this;
    },
    json(body) {
      sent.body = body;
      return this;
    },
  };
  return {res, sent};
}

/**
 * Crea un request Express falso con la cabecera de App Check indicada.
 * @param {string|undefined} token Valor de la cabecera, o `undefined` si no
 *   viene ninguna.
 * @return {object} Request falso con `.header()`.
 */
function createFakeReq(token) {
  return {
    header: (name) => (name === APP_CHECK_HEADER ? token : undefined),
  };
}

test("rechaza con 401 si no viene la cabecera de App Check", async () => {
  const appCheck = {verifyToken: async () => assert.fail("no debería llamarse")};
  const guard = createAppCheckGuard({appCheck});
  const {res, sent} = createFakeRes();

  const ok = await guard(createFakeReq(undefined), res);

  assert.strictEqual(ok, false);
  assert.strictEqual(sent.status, 401);
});

test("rechaza con 401 si el token no es válido", async () => {
  const appCheck = {verifyToken: async () => { throw new Error("token inválido"); }};
  const guard = createAppCheckGuard({appCheck});
  const {res, sent} = createFakeRes();

  const ok = await guard(createFakeReq("token-falso"), res);

  assert.strictEqual(ok, false);
  assert.strictEqual(sent.status, 401);
});

test("deja pasar el pedido si el token es válido", async () => {
  let verified = null;
  const appCheck = {
    verifyToken: async (token) => {
      verified = token;
      return {appId: "app-de-prueba"};
    },
  };
  const guard = createAppCheckGuard({appCheck});
  const {res, sent} = createFakeRes();

  const ok = await guard(createFakeReq("token-valido"), res);

  assert.strictEqual(ok, true);
  assert.strictEqual(verified, "token-valido");
  assert.strictEqual(sent.status, null);
});

test("con enforce:false, deja pasar igual aunque falte el token", async () => {
  const appCheck = {verifyToken: async () => assert.fail("no debería llamarse")};
  const guard = createAppCheckGuard({appCheck, enforce: false});
  const {res, sent} = createFakeRes();

  const ok = await guard(createFakeReq(undefined), res);

  assert.strictEqual(ok, true);
  assert.strictEqual(sent.status, null);
});

test("con enforce:false, deja pasar igual aunque el token sea inválido", async () => {
  const appCheck = {verifyToken: async () => { throw new Error("token inválido"); }};
  const guard = createAppCheckGuard({appCheck, enforce: false});
  const {res, sent} = createFakeRes();

  const ok = await guard(createFakeReq("token-cualquiera"), res);

  assert.strictEqual(ok, true);
  assert.strictEqual(sent.status, null);
});
