const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Authorization, Content-Type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

const json = (data, status = 200) => new Response(JSON.stringify(data), { status, headers: cors });
const fail = (message, status = 400) => json({ error: message }, status);

function b64url(bytes) {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}
const enc = new TextEncoder();

async function googleAccessToken(env) {
  const sa = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT_JSON);
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(enc.encode(JSON.stringify({ alg: "RS256", typ: "JWT" })));
  const claims = b64url(enc.encode(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/datastore",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  })));
  const unsigned = header + "." + claims;
  const pem = sa.private_key.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g, "");
  const key = await crypto.subtle.importKey("pkcs8", Uint8Array.from(atob(pem), c => c.charCodeAt(0)), { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, enc.encode(unsigned));
  const assertion = unsigned + "." + b64url(new Uint8Array(sig));
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion }),
  });
  if (!response.ok) throw new Error("Google service authentication failed");
  return (await response.json()).access_token;
}

async function firestore(env, path, method = "GET", body = null) {
  const token = await googleAccessToken(env);
  const url = "https://firestore.googleapis.com/v1/projects/" + env.FIREBASE_PROJECT_ID + "/databases/(default)/documents/" + path;
  const response = await fetch(url, {
    method, headers: { Authorization: "Bearer " + token, "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!response.ok) throw new Error("Firestore request failed (" + response.status + ")");
  return response.status === 204 ? null : response.json();
}

const fsString = value => ({ stringValue: String(value) });
const fsInt = value => ({ integerValue: String(value) });
const fsTimestamp = value => ({ timestampValue: new Date(value).toISOString() });
function paymentFields(p) {
  return { userId: fsString(p.userId), amount: fsInt(50), paymentReference: fsString(p.provider + " mobile-money push"),
    provider: fsString(p.provider), providerReference: fsString(p.providerReference), phoneLast4: fsString(p.phoneLast4),
    status: fsString(p.status), providerStatus: fsString(p.providerStatus), requestId: fsString(p.requestId),
    submittedAt: fsTimestamp(p.createdAt), paymentMethod: fsString("mobile_money_push") };
}
async function savePayment(env, p) {
  await firestore(env, "payments/" + encodeURIComponent(p.id), "PATCH", { fields: paymentFields(p) });
}
async function saveSubscription(env, uid, paymentId) {
  const now = new Date();
  await firestore(env, "subscriptions/" + encodeURIComponent(uid), "PATCH", { fields: {
    userId: fsString(uid), status: fsString("active"), startDate: fsTimestamp(now),
    expiryDate: fsTimestamp(new Date(now.getTime() + 30 * 86400000)), amount: fsInt(50),
    paymentReference: fsString(paymentId), approvedBy: fsString("verified-provider"), createdAt: fsTimestamp(now),
  }});
}

async function authenticate(request, env) {
  const token = (request.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
  if (!token) return null;
  const response = await fetch("https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=" + encodeURIComponent(env.FIREBASE_WEB_API_KEY), {
    method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ idToken: token }),
  });
  if (!response.ok) return null;
  const data = await response.json();
  return data.users?.[0]?.localId || null;
}
function normalizePhone(value) {
  const digits = String(value || "").replace(/[\s()+-]/g, "");
  if (/^0[0-9]{9}$/.test(digits)) return "260" + digits.slice(1);
  if (/^260[0-9]{9}$/.test(digits)) return digits;
  throw new Error("Enter a valid Zambian mobile number.");
}
async function providerFetch(url, options) {
  const response = await fetch(url, options);
  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    const error = new Error("Mobile-money provider rejected the request.");
    error.status = response.status;
    throw error;
  }
  return { status: response.status, body };
}
async function mtnToken(env) {
  const base = env.MTN_API_BASE || "https://proxy.momoapi.mtn.com";
  const basic = btoa(env.MTN_COLLECTION_API_USER + ":" + env.MTN_COLLECTION_API_KEY);
  const result = await providerFetch(base + "/collection/token/", { method: "POST", headers: {
    Authorization: "Basic " + basic, "Ocp-Apim-Subscription-Key": env.MTN_COLLECTION_SUBSCRIPTION_KEY,
  }});
  if (!result.body.access_token) throw new Error("MTN authentication failed");
  return { token: result.body.access_token, base };
}
async function startProvider(env, p, phone) {
  if (p.provider === "MTN") {
    const { token, base } = await mtnToken(env);
    const result = await providerFetch(base + "/collection/v1_0/requesttopay", { method: "POST", headers: {
      Authorization: "Bearer " + token, "X-Reference-Id": p.providerReference,
      "X-Target-Environment": env.MTN_TARGET_ENVIRONMENT || "mtnzambia",
      "Ocp-Apim-Subscription-Key": env.MTN_COLLECTION_SUBSCRIPTION_KEY, "Content-Type": "application/json",
    }, body: JSON.stringify({ amount: "50", currency: "ZMW", externalId: p.id,
      payer: { partyIdType: "MSISDN", partyId: phone },
      payerMessage: "Engineering Drawing City subscription", payeeNote: "K50 subscription for 30 days" }) });
    if (result.status !== 202) throw new Error("MTN did not accept the payment request");
    return;
  }
  const base = env.AIRTEL_API_BASE || "https://openapi.airtel.africa";
  const auth = await providerFetch(base + "/auth/oauth2/token", { method: "POST", headers: { "Content-Type": "application/json", Accept: "application/json" },
    body: JSON.stringify({ client_id: env.AIRTEL_CLIENT_ID, client_secret: env.AIRTEL_CLIENT_SECRET, grant_type: "client_credentials" }) });
  if (!auth.body.access_token) throw new Error("Airtel authentication failed");
  const result = await providerFetch(base + "/merchant/v1/payments/", { method: "POST", headers: {
    Authorization: "Bearer " + auth.body.access_token, "Content-Type": "application/json", Accept: "application/json", "X-Country": "ZM", "X-Currency": "ZMW",
  }, body: JSON.stringify({ reference: p.providerReference, subscriber: { country: "ZM", currency: "ZMW", msisdn: phone },
    transaction: { amount: 50, country: "ZM", currency: "ZMW", id: p.providerReference } }) });
  const code = result.body?.data?.transaction?.status_code;
  if (result.status !== 200 || (code && !["TS", "SUCCESS", "SUCCESSFUL"].includes(String(code).toUpperCase()))) throw new Error("Airtel did not accept the payment request");
}
async function providerStatus(env, p) {
  if (p.provider === "MTN") {
    const { token, base } = await mtnToken(env);
    return (await providerFetch(base + "/collection/v1_0/requesttopay/" + encodeURIComponent(p.providerReference), {
      headers: { Authorization: "Bearer " + token, "X-Target-Environment": env.MTN_TARGET_ENVIRONMENT || "mtnzambia", "Ocp-Apim-Subscription-Key": env.MTN_COLLECTION_SUBSCRIPTION_KEY },
    })).body;
  }
  const base = env.AIRTEL_API_BASE || "https://openapi.airtel.africa";
  const auth = await providerFetch(base + "/auth/oauth2/token", { method: "POST", headers: { "Content-Type": "application/json", Accept: "application/json" },
    body: JSON.stringify({ client_id: env.AIRTEL_CLIENT_ID, client_secret: env.AIRTEL_CLIENT_SECRET, grant_type: "client_credentials" }) });
  const body = (await providerFetch(base + "/standard/v1/payments/" + encodeURIComponent(p.providerReference), {
    headers: { Authorization: "Bearer " + auth.body.access_token, Accept: "application/json", "X-Country": "ZM", "X-Currency": "ZMW" },
  })).body;
  return body?.data?.transaction || body?.transaction || body?.data || body;
}
function normalizeStatus(value) {
  const s = String(value || "").toUpperCase();
  if (["SUCCESSFUL", "SUCCESS", "COMPLETED", "TS"].includes(s)) return "successful";
  if (["FAILED", "FAILURE", "REJECTED", "DECLINED", "EXPIRED", "CANCELLED"].includes(s)) return "failed";
  return "pending";
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
    if (request.method !== "POST") return fail("POST required", 405);
    const uid = await authenticate(request, env);
    if (!uid) return fail("Please sign in again.", 401);
    const url = new URL(request.url);
    try {
      if (url.pathname === "/payments/initiate") {
        const data = await request.json();
        const provider = String(data.provider || "").toUpperCase();
        if (!["MTN", "AIRTEL"].includes(provider)) return fail("Select Airtel Money or MTN MoMo.");
        const phone = normalizePhone(data.phone);
        const requestId = String(data.requestId || "");
        if (!/^[A-Za-z0-9_-]{20,100}$/.test(requestId)) return fail("Invalid payment request.");
        const id = "mm_" + uid + "_" + requestId;
        const existing = await env.PAYMENTS.prepare("SELECT * FROM payments WHERE user_id=? AND status='pending' ORDER BY created_at LIMIT 1").bind(uid).first();
        if (existing) return json({ paymentId: existing.id, status: "pending", alreadyRequested: true });
        const p = { id, userId: uid, provider, providerReference: crypto.randomUUID(), phoneLast4: phone.slice(-4),
          requestId, status: "pending", providerStatus: "initiating", createdAt: new Date().toISOString() };
        const lock = await env.PAYMENTS.prepare("INSERT OR IGNORE INTO payments (id,user_id,provider,provider_ref,phone_last4,request_id,status,provider_status,created_at) VALUES (?,?,?,?,?,?,?,?,?)")
          .bind(p.id, uid, provider, p.providerReference, p.phoneLast4, requestId, p.status, p.providerStatus, p.createdAt).run();
        if (!lock.meta.changes) {
          const saved = await env.PAYMENTS.prepare("SELECT * FROM payments WHERE id=?").bind(id).first();
          return json({ paymentId: saved?.id || id, status: saved?.status || "pending", alreadyRequested: true });
        }
        try {
          await savePayment(env, p);
          await startProvider(env, p, phone);
          p.providerStatus = "pending";
          await env.PAYMENTS.prepare("UPDATE payments SET provider_status=? WHERE id=?").bind("pending", id).run();
          return json({ paymentId: id, status: "pending", alreadyRequested: false });
        } catch (e) {
          p.providerStatus = "unknown";
          await env.PAYMENTS.prepare("UPDATE payments SET provider_status=? WHERE id=?").bind("unknown", id).run();
          return json({ paymentId: id, status: "pending", message: "Request outcome is uncertain. Do not initiate another payment." });
        }
      }
      if (url.pathname === "/payments/status") {
        const data = await request.json();
        const id = String(data.paymentId || "");
        const p = await env.PAYMENTS.prepare("SELECT * FROM payments WHERE id=? AND user_id=?").bind(id, uid).first();
        if (!p) return fail("Payment request not found.", 404);
        if (p.status !== "pending") return json({ status: p.status });
        const payment = { id: p.id, userId: uid, provider: p.provider, providerReference: p.provider_ref,
          phoneLast4: p.phone_last4, requestId: p.request_id, status: p.status, providerStatus: p.provider_status, createdAt: p.created_at };
        let result;
        try { result = await providerStatus(env, payment); } catch (_) { return json({ status: "pending" }); }
        const status = normalizeStatus(result.status || result.status_code);
        if (status === "successful") {
          const amount = Number(result.amount ?? result.transaction?.amount);
          const currency = String(result.currency ?? result.transaction?.currency ?? "").toUpperCase();
          if (amount !== 50 || currency !== "ZMW") return fail("Provider confirmation did not match K50 ZMW. Payment is held for review.", 409);
          await saveSubscription(env, uid, id);
          await env.PAYMENTS.prepare("UPDATE payments SET status='approved',provider_status='successful' WHERE id=? AND user_id=? AND status='pending'").bind(id, uid).run();
          await firestore(env, "payments/" + encodeURIComponent(id), "PATCH", { fields: {
            status: fsString("approved"), providerStatus: fsString("successful"), reviewedAt: fsTimestamp(new Date()), reviewedBy: fsString("verified-provider"),
          }});
          return json({ status: "approved" });
        }
        if (status === "failed") {
          await env.PAYMENTS.prepare("UPDATE payments SET status='rejected',provider_status='failed' WHERE id=? AND user_id=? AND status='pending'").bind(id, uid).run();
          await firestore(env, "payments/" + encodeURIComponent(id), "PATCH", { fields: { status: fsString("rejected"), providerStatus: fsString("failed") }});
          return json({ status: "rejected" });
        }
        return json({ status: "pending" });
      }
      return fail("Not found", 404);
    } catch (e) {
      return fail(e.message || "Payment service error", 500);
    }
  },
};
