const {setGlobalOptions} = require("firebase-functions");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();
setGlobalOptions({maxInstances: 10, region: "africa-south1"});

const mtnCollectionKey = defineSecret("MTN_COLLECTION_SUBSCRIPTION_KEY");
const mtnApiUser = defineSecret("MTN_COLLECTION_API_USER");
const mtnApiKey = defineSecret("MTN_COLLECTION_API_KEY");
const airtelClientId = defineSecret("AIRTEL_CLIENT_ID");
const airtelClientSecret = defineSecret("AIRTEL_CLIENT_SECRET");

const db = admin.firestore();
const AMOUNT = 50;
const CURRENCY = "ZMW";
const PROVIDER_TIMEOUT_MS = 15000;

function normalizeZambianMsisdn(value) {
  const digits = String(value || "").replace(/[\s()+-]/g, "");
  if (/^0[0-9]{9}$/.test(digits)) return "260" + digits.slice(1);
  if (/^260[0-9]{9}$/.test(digits)) return digits;
  throw new HttpsError("invalid-argument", "Enter a valid Zambian mobile number.");
}

function providerStatus(value) {
  const status = String(value || "").toUpperCase();
  if (["SUCCESSFUL", "SUCCESS", "COMPLETED", "TS"].includes(status)) return "successful";
  if (["FAILED", "FAILURE", "REJECTED", "DECLINED", "EXPIRED", "CANCELLED"].includes(status)) return "failed";
  return "pending";
}

async function fetchJson(url, options = {}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), PROVIDER_TIMEOUT_MS);
  try {
    const response = await fetch(url, {...options, signal: controller.signal});
    const bodyText = await response.text();
    let body = {};
    try { body = bodyText ? JSON.parse(bodyText) : {}; } catch (_) {}
    if (!response.ok) {
      logger.warn("Mobile-money provider returned an error", {status: response.status});
      throw new Error("Payment provider could not process the request.");
    }
    return {status: response.status, body};
  } finally {
    clearTimeout(timeout);
  }
}

async function mtnToken() {
  const auth = Buffer.from(mtnApiUser.value() + ":" + mtnApiKey.value()).toString("base64");
  const base = process.env.MTN_API_BASE || "https://momodeveloper.mtn.com";
  const result = await fetchJson(base + "/collection/token/", {
    method: "POST",
    headers: {
      "Authorization": "Basic " + auth,
      "Ocp-Apim-Subscription-Key": mtnCollectionKey.value(),
    },
  });
  if (!result.body.access_token) throw new Error("MTN authentication failed.");
  return {token: result.body.access_token, base};
}

async function startMtnPayment(paymentId, msisdn) {
  const {token, base} = await mtnToken();
  const target = process.env.MTN_TARGET_ENVIRONMENT || "production";
  const result = await fetchJson(base + "/collection/v1_0/requesttopay", {
    method: "POST",
    headers: {
      "Authorization": "Bearer " + token,
      "X-Reference-Id": paymentId,
      "X-Target-Environment": target,
      "Ocp-Apim-Subscription-Key": mtnCollectionKey.value(),
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      amount: String(AMOUNT),
      currency: CURRENCY,
      externalId: paymentId,
      payer: {partyIdType: "MSISDN", partyId: msisdn},
      payerMessage: "Engineering Drawing City subscription",
      payeeNote: "K50 subscription for 30 days",
    }),
  });
  if (result.status !== 202) throw new Error("MTN did not accept the payment request.");
}

async function checkMtnPayment(paymentId) {
  const {token, base} = await mtnToken();
  const result = await fetchJson(base + "/collection/v1_0/requesttopay/" + encodeURIComponent(paymentId), {
    method: "GET",
    headers: {
      "Authorization": "Bearer " + token,
      "X-Target-Environment": process.env.MTN_TARGET_ENVIRONMENT || "production",
      "Ocp-Apim-Subscription-Key": mtnCollectionKey.value(),
    },
  });
  return providerStatus(result.body.status);
}

async function airtelToken() {
  const base = process.env.AIRTEL_API_BASE || "https://openapi.airtel.africa";
  const auth = Buffer.from(airtelClientId.value() + ":" + airtelClientSecret.value()).toString("base64");
  const result = await fetchJson(base + "/auth/oauth2/token", {
    method: "POST",
    headers: {
      "Authorization": "Basic " + auth,
      "Content-Type": "application/json",
      "Accept": "application/json",
    },
    body: JSON.stringify({grant_type: "client_credentials"}),
  });
  if (!result.body.access_token) throw new Error("Airtel authentication failed.");
  return {token: result.body.access_token, base};
}

async function startAirtelPayment(paymentId, msisdn) {
  const {token, base} = await airtelToken();
  const result = await fetchJson(base + "/merchant/v1/payments/", {
    method: "POST",
    headers: {
      "Authorization": "Bearer " + token,
      "Content-Type": "application/json",
      "Accept": "application/json",
      "X-Country": "ZM",
      "X-Currency": CURRENCY,
    },
    body: JSON.stringify({
      reference: paymentId,
      subscriber: {country: "ZM", currency: CURRENCY, msisdn},
      transaction: {amount: AMOUNT, country: "ZM", currency: CURRENCY, id: paymentId},
    }),
  });
  const code = result.body?.data?.transaction?.status_code;
  if (result.status !== 200 || (code && !["TS", "SUCCESS", "SUCCESSFUL"].includes(String(code).toUpperCase()))) {
    throw new Error("Airtel did not accept the payment request.");
  }
}

async function checkAirtelPayment(paymentId) {
  const {token, base} = await airtelToken();
  const result = await fetchJson(base + "/standard/v1/payments/" + encodeURIComponent(paymentId), {
    method: "GET",
    headers: {
      "Authorization": "Bearer " + token,
      "Accept": "application/json",
      "X-Country": "ZM",
      "X-Currency": CURRENCY,
    },
  });
  const data = result.body?.data || result.body;
  return providerStatus(data?.transaction?.status || data?.status || data?.transaction?.status_code);
}

function secretsFor(provider) {
  return provider === "MTN"
    ? [mtnCollectionKey, mtnApiUser, mtnApiKey]
    : [airtelClientId, airtelClientSecret];
}

exports.requestMobileMoneyPayment = onCall({
  secrets: [mtnCollectionKey, mtnApiUser, mtnApiKey, airtelClientId, airtelClientSecret],
  enforceAppCheck: false,
}, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in before paying.");
  const provider = String(request.data?.provider || "").toUpperCase();
  if (!["MTN", "AIRTEL"].includes(provider)) throw new HttpsError("invalid-argument", "Choose Airtel Money or MTN MoMo.");
  const msisdn = normalizeZambianMsisdn(request.data?.phone);
  const requestId = String(request.data?.requestId || "");
  if (!/^[A-Za-z0-9_-]{20,80}$/.test(requestId)) {
    throw new HttpsError("invalid-argument", "Invalid payment request reference.");
  }
  const paymentId = "mm_" + request.auth.uid + "_" + requestId;
  const paymentRef = db.collection("payments").doc(paymentId);

  // Reserve the payment before contacting the carrier. A retry with the same
  // requestId returns this record and NEVER sends a second push request.
  const reservation = await db.runTransaction(async (tx) => {
    const existing = await tx.get(paymentRef);
    if (existing.exists) return {existing: true, data: existing.data(), id: paymentId};
    const outstandingQuery = db.collection("payments")
      .where("userId", "==", request.auth.uid)
      .where("paymentMethod", "==", "mobile_money_push")
      .where("status", "==", "pending")
      .limit(1);
    const outstanding = await tx.get(outstandingQuery);
    if (!outstanding.empty) {
      const doc = outstanding.docs[0];
      return {existing: true, data: doc.data(), id: doc.id};
    }
    const data = {
      userId: request.auth.uid,
      amount: AMOUNT,
      paymentReference: provider + " mobile-money push",
      provider,
      providerReference: paymentId,
      phoneLast4: msisdn.slice(-4),
      status: "pending",
      providerStatus: "initiating",
      requestId,
      submittedAt: new Date().toISOString(),
      paymentMethod: "mobile_money_push",
    };
    tx.create(paymentRef, data);
    return {existing: false, data, id: paymentId};
  });

  if (reservation.existing) {
    return {paymentId: reservation.id, status: reservation.data.status || "pending", alreadyRequested: true};
  }

  try {
    if (provider === "MTN") await startMtnPayment(paymentId, msisdn);
    else await startAirtelPayment(paymentId, msisdn);
    await paymentRef.update({providerStatus: "pending", requestAcceptedAt: admin.firestore.FieldValue.serverTimestamp()});
    return {paymentId, status: "pending", alreadyRequested: false};
  } catch (error) {
    // Do not automatically retry an uncertain request: it could have reached
    // the carrier. Keep it pending for reconciliation instead of risking a
    // duplicate charge.
    logger.error("Mobile-money initiation outcome uncertain", {paymentId, provider});
    await paymentRef.update({providerStatus: "unknown", initiationMessage: "Check payment status before retrying."});
    return {paymentId, status: "pending", alreadyRequested: false, message: "The request may be processing. Do not start another payment."};
  }
});

exports.refreshMobileMoneyPayment = onCall({
  secrets: [mtnCollectionKey, mtnApiUser, mtnApiKey, airtelClientId, airtelClientSecret],
  enforceAppCheck: true,
}, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in to check your payment.");
  const paymentId = String(request.data?.paymentId || "");
  if (!paymentId.startsWith("mm_" + request.auth.uid + "_")) {
    throw new HttpsError("permission-denied", "This payment does not belong to your account.");
  }
  const ref = db.collection("payments").doc(paymentId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Payment request not found.");
  const payment = snap.data();
  if (payment.userId !== request.auth.uid) throw new HttpsError("permission-denied", "Payment owner mismatch.");
  if (payment.status === "approved" || payment.status === "rejected") return {status: payment.status};
  const provider = payment.provider;
  let status = "pending";
  try {
    status = provider === "MTN" ? await checkMtnPayment(paymentId) : await checkAirtelPayment(paymentId);
  } catch (error) {
    logger.warn("Payment status check failed", {paymentId, provider});
    return {status: "pending"};
  }

  if (status === "successful") {
    await db.runTransaction(async (tx) => {
      const fresh = await tx.get(ref);
      if (!fresh.exists || fresh.data().status === "approved") return;
      const now = admin.firestore.Timestamp.now();
      const subscriptionRef = db.collection("subscriptions").doc(request.auth.uid);
      tx.update(ref, {
        status: "approved",
        providerStatus: "successful",
        reviewedAt: new Date().toISOString(),
        reviewedBy: "verified-provider",
      });
      tx.set(subscriptionRef, {
        userId: request.auth.uid,
        status: "active",
        startDate: now,
        expiryDate: admin.firestore.Timestamp.fromMillis(now.toMillis() + 30 * 24 * 60 * 60 * 1000),
        amount: AMOUNT,
        paymentReference: paymentId,
        approvedBy: "verified-provider",
        createdAt: now,
      });
    });
    return {status: "approved"};
  }
  if (status === "failed") {
    await ref.update({status: "rejected", providerStatus: "failed"});
    return {status: "rejected"};
  }
  await ref.update({providerStatus: "pending"});
  return {status: "pending"};
});
