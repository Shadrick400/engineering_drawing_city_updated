# Engineering Drawing City payment Worker

This backend is designed for Cloudflare Workers Free + D1 Free. It does not deploy Firebase Cloud Functions and does not require Firebase Blaze.

## Important release status

This is an integration draft, not a live payment service. Provider merchant onboarding, approved production credentials, API contract verification, automated tests, Firestore security review, and sandbox tests are required before collecting real money. Do not merge or deploy for production yet.

## Create the free backend

1. Create a Cloudflare account and install Wrangler (Node.js 20+).
2. From this directory, run `npx wrangler d1 create engineering-drawing-city-payments`.
3. Copy the returned database ID into `wrangler.toml`.
4. Run `npx wrangler d1 migrations apply engineering-drawing-city-payments --remote`.
5. Add secrets with `npx wrangler secret put SECRET_NAME` (Wrangler prompts for the value). Required: `FIREBASE_WEB_API_KEY`, `FIREBASE_SERVICE_ACCOUNT_JSON`, `MTN_COLLECTION_SUBSCRIPTION_KEY`, `MTN_COLLECTION_API_USER`, `MTN_COLLECTION_API_KEY`, `AIRTEL_CLIENT_ID`, `AIRTEL_CLIENT_SECRET`.
6. Set non-secret vars `FIREBASE_PROJECT_ID`, `MTN_API_BASE`, `MTN_TARGET_ENVIRONMENT`, and `AIRTEL_API_BASE` in Worker settings.
7. Deploy with `npx wrangler deploy`.
8. Build the Flutter app with `--dart-define=EDC_PAYMENT_API_URL=https://YOUR-WORKER.workers.dev`.

The service account must be dedicated to this Worker and have only the minimum Firestore permissions required. Never commit its JSON key, provider credentials, or `.dev.vars`. Rotate credentials if they are exposed. Do not use a project owner service account.

## Local checks

From this directory, run:

```sh
npm test
```

These initial Node tests cover phone normalization, provider status normalization, CORS preflight, HTTP method rejection, and the unauthenticated request boundary. They do not mock live Airtel/MTN APIs or prove production payment correctness.

## Endpoints

- `POST /payments/initiate` with Firebase ID token and JSON `{provider, phone, requestId}`.
- `POST /payments/status` with Firebase ID token and JSON `{paymentId}`.

The Worker verifies the Firebase ID token through Firebase Identity Toolkit, reserves a D1 per-user pending lock, and sends one provider initiation. Status checks are owner-scoped. Only provider-confirmed success with matching amount/currency should activate the subscription.

## Required before production

- Confirm provider-specific status response fields and amount/currency values for both Zambia merchant APIs. If the provider does not return verifiable amount/currency, use a provider transaction-detail endpoint or signed callback before granting access.
- Add provider callback signature validation, strict CORS/origin policy for web builds, rate limiting/abuse controls, and structured audit logging without secrets or full phone numbers.
- Add automated tests for duplicate taps, request retries, lock races, pending/unknown outcomes, successful/failed payments, amount/currency mismatch, subscription expiry, and Firestore failures.
- Review Firestore rules: clients must not create or approve payment documents or write subscriptions. This Worker uses a dedicated service identity to write verified records.
- Validate all D1 and Firestore failure recovery paths and reconcile cases where a provider debit succeeds but Firestore update fails.
- Run Flutter analyze/tests and Worker tests, then complete Airtel/MTN sandbox tests.

Cloudflare free hosting does not remove provider transaction fees, merchant onboarding, or any Firebase usage limits. Firebase Auth and Firestore remain on Spark; do not enable Blaze.
