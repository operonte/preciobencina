const test = require("node:test");
const assert = require("node:assert");

const {decodeJwtExpiry, createCneAuth, REFRESH_BUFFER_MS} = require("../lib/cneAuth");

/**
 * Construye un JWT de prueba (header.payload.firma) con el `exp` indicado.
 * @param {number} expSeconds Marca "exp" en segundos epoch.
 * @return {string} Token con el formato de un JWT.
 */
function makeToken(expSeconds) {
  const payload = Buffer.from(JSON.stringify({exp: expSeconds})).toString("base64url");
  return `header.${payload}.signature`;
}

/**
 * Crea una base de datos falsa con un único documento `cne_auth/token`.
 * @param {object|undefined} initial Valor inicial del documento.
 * @return {{db: object, getStored: function(): object}} Db falsa y getter.
 */
function createFakeDb(initial) {
  let stored = initial;
  const db = {
    collection: () => ({
      doc: () => ({
        get: async () => ({data: () => stored}),
        set: async (value) => {
          stored = value;
        },
      }),
    }),
  };
  return {db, getStored: () => stored};
}

test("decodeJwtExpiry lee el campo exp en milisegundos", () => {
  const token = makeToken(1_700_000_000);
  assert.strictEqual(decodeJwtExpiry(token), 1_700_000_000_000);
});

test("getValidToken reutiliza el token cacheado si no está por vencer", async () => {
  const cachedToken = makeToken(Math.floor(Date.now() / 1000) + 3600);
  const {db} = createFakeDb({
    token: cachedToken,
    expiresAt: Date.now() + 3600_000,
  });

  let loginCalls = 0;
  const axiosClient = {
    post: async () => {
      loginCalls++;
      return {data: {token: makeToken(Math.floor(Date.now() / 1000) + 7200)}};
    },
  };

  const auth = createCneAuth({
    db,
    axiosClient,
    getCredentials: () => ({email: "a@b.cl", password: "x"}),
  });

  const token = await auth.getValidToken();

  assert.strictEqual(token, cachedToken);
  assert.strictEqual(loginCalls, 0);
});

test("getValidToken inicia sesión si no hay token cacheado", async () => {
  const {db, getStored} = createFakeDb(undefined);
  const freshToken = makeToken(Math.floor(Date.now() / 1000) + 7200);

  let loginCalls = 0;
  const axiosClient = {
    post: async (url, body) => {
      loginCalls++;
      assert.deepStrictEqual(body, {email: "a@b.cl", password: "x"});
      return {data: {token: freshToken}};
    },
  };

  const auth = createCneAuth({
    db,
    axiosClient,
    getCredentials: () => ({email: "a@b.cl", password: "x"}),
  });

  const token = await auth.getValidToken();

  assert.strictEqual(token, freshToken);
  assert.strictEqual(loginCalls, 1);
  assert.strictEqual(getStored().token, freshToken);
});

test("getValidToken renueva el token si está por vencer", async () => {
  const expiringToken = makeToken(Math.floor(Date.now() / 1000) + 30);
  const {db} = createFakeDb({
    token: expiringToken,
    // Vence dentro del REFRESH_BUFFER_MS, así que debe renovarse.
    expiresAt: Date.now() + REFRESH_BUFFER_MS / 2,
  });

  const freshToken = makeToken(Math.floor(Date.now() / 1000) + 7200);
  let loginCalls = 0;
  const axiosClient = {
    post: async () => {
      loginCalls++;
      return {data: {token: freshToken}};
    },
  };

  const auth = createCneAuth({
    db,
    axiosClient,
    getCredentials: () => ({email: "a@b.cl", password: "x"}),
  });

  const token = await auth.getValidToken();

  assert.strictEqual(token, freshToken);
  assert.strictEqual(loginCalls, 1);
});

test("loginAndCacheToken guarda el token y su expiración en Firestore", async () => {
  const {db, getStored} = createFakeDb(undefined);
  const expSeconds = Math.floor(Date.now() / 1000) + 7200;
  const token = makeToken(expSeconds);

  const axiosClient = {
    post: async () => ({data: {token}}),
  };

  const auth = createCneAuth({
    db,
    axiosClient,
    getCredentials: () => ({email: "a@b.cl", password: "x"}),
  });

  const result = await auth.loginAndCacheToken();

  assert.strictEqual(result, token);
  assert.deepStrictEqual(getStored(), {token, expiresAt: expSeconds * 1000});
});
