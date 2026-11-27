# Engineering Drawing City — Zambia mobile-money payments

Engineering Drawing City uses a K50 / 30-day subscription. The payment checkout is designed to send a single wallet push only after the student taps **Pay K50**.

## Free-tier architecture

- Firebase Spark: Firebase Authentication and Firestore.
- Cloudflare Workers Free: payment API.
- Cloudflare D1 Free: idempotency and pending-payment lock.
- No Firebase Cloud Functions payment backend; do not enable Firebase Blaze for this feature.

Cloudflare free hosting does not make provider merchant transactions free. Airtel Money and MTN MoMo require merchant/API onboarding and may charge transaction fees.

## Flow

1. The signed-in student chooses Airtel Money or MTN MoMo and enters their wallet number.
2. Flutter sends a Firebase ID token to the Cloudflare Worker.
3. The Worker verifies the token with Firebase Identity Toolkit, reserves a D1 pending lock, writes a payment record to Firestore, and sends one provider request.
4. The customer approves the provider's wallet prompt using their PIN in the provider's own flow. The app never asks for a wallet PIN or OTP.
5. The app checks the existing request. Only a verified successful provider status with the expected amount and ZMW currency may activate the 30-day subscription.
6. Uncertain outcomes stay pending; the user must not initiate another payment until reconciled.

## Worker setup

See [cloudflare-payments/README.md](../cloudflare-payments/README.md) for the Worker, D1, secrets, and deployment steps. Configure Flutter with:

```sh
flutter build apk --dart-define=EDC_PAYMENT_API_URL=https://YOUR-WORKER.workers.dev
```

Do not store service-account JSON or provider credentials in Flutter, Git, or public files. Use Cloudflare Worker secrets. Use a dedicated service account with the minimum Firestore permissions; never use a project-owner key.

## Current status / release gate

This remains a **draft integration**. Do not merge or collect live money yet. The Worker and Flutter integration have not been run or tested because the development PC is unavailable.

Before production:
- Confirm current Airtel and MTN Zambia merchant API contracts, production access, and returned transaction amount/currency fields.
- Test successful, rejected, expired, duplicate, delayed, and ambiguous payments in both sandboxes.
- Ensure Firestore rules deny client creation/update of payment records and subscription documents. The trusted Worker service identity must be the only automated payment writer.
- Review Worker/D1/Firestore consistency and recovery when a provider debit succeeds but a Firestore write fails.
- Add provider callback signature verification, abuse/rate limiting, strict browser origin policy, and safe audit logs.
- Run Flutter analyze/tests and Worker tests, then verify no Firebase billing plan change is needed.

Never grant access based on an SMS screenshot, user-entered transaction reference, or provider HTTP acceptance alone.
