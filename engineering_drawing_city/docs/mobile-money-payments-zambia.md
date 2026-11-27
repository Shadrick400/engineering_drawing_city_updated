# Engineering Drawing City — Zambia mobile-money push payments

Engineering Drawing City uses a K50 / 30-day subscription. The checkout is designed for one-tap initiation: a student chooses Airtel Money or MTN MoMo, enters their wallet number, and taps **Pay K50** once. The app sends one provider request, then checks the existing request until the provider confirms success or failure.

## Payment flow

1. The authenticated student selects a network and enters a Zambian mobile number.
2. The app calls the authenticated Firebase callable `requestMobileMoneyPayment` once.
3. The server reserves a Firestore payment record before calling the provider. The request ID is idempotent, and a pending mobile-money request blocks creation of another pending request for that account.
4. MTN uses Request to Pay; Airtel uses its merchant payment initiation endpoint. The wallet provider sends the approval prompt to the customer's handset.
5. The customer enters their wallet PIN only in the provider's own phone prompt. The app never collects a PIN or OTP.
6. The app calls `refreshMobileMoneyPayment` to query the provider. Only a provider-verified successful status can atomically approve the payment and activate the 30-day subscription.
7. If the outcome is uncertain, the payment remains pending. Do not initiate another payment until the existing request has been reconciled.

A provider's HTTP acceptance (such as MTN 202 Accepted) is **not** proof of payment. The server must query the provider status. The provider callback can be added as a notification optimization later; status polling is the fallback.

## Backend functions

- `requestMobileMoneyPayment`: authenticated request creation, idempotency, pending payment reservation, and one provider initiation.
- `refreshMobileMoneyPayment`: ownership-checked provider status query; atomically marks the payment approved and writes the subscription only after success.
- Firestore payment documents keep the provider name, provider reference, masked phone suffix, request ID, and status. No wallet PIN/OTP is stored.

## Merchant onboarding and secret setup

Live requests cannot work until Engineering Drawing City has approved merchant/API credentials for both networks. Register for official MTN MoMo Collection and Airtel Money merchant/API access, complete business/KYC onboarding, and confirm that Zambia (ZM) / ZMW collections are enabled for the accounts.

Set these Firebase Functions secrets locally through the Firebase CLI (the CLI prompts for the secret value; never commit or paste the values into source code or chat):

```sh
firebase functions:secrets:set MTN_COLLECTION_SUBSCRIPTION_KEY
firebase functions:secrets:set MTN_COLLECTION_API_USER
firebase functions:secrets:set MTN_COLLECTION_API_KEY
firebase functions:secrets:set AIRTEL_CLIENT_ID
firebase functions:secrets:set AIRTEL_CLIENT_SECRET
```

Set non-secret provider environment values in the Functions environment file (keep that file out of Git):

```dotenv
MTN_API_BASE=https://proxy.momoapi.mtn.com
MTN_TARGET_ENVIRONMENT=mtnzambia
AIRTEL_API_BASE=https://openapi.airtel.africa
```

Use the exact MTN target environment and production API base supplied by MTN for the approved Zambia merchant account. For sandbox testing, use the sandbox endpoint and environment given by the provider; do not mix sandbox credentials with production endpoints.

Then deploy from the Flutter project directory:

```sh
cd engineering_drawing_city/functions
npm install
cd ..
firebase deploy --only functions
```

Firebase Cloud Functions deployment generally requires the Firebase project to be on the Blaze billing plan. Review billing and provider transaction fees before enabling live collection. Do not deploy live until both merchant accounts, secrets, and provider configuration are verified.

## Release checklist

- Test one approved payment and one rejected/expired payment in provider sandbox.
- Confirm a single tap creates only one provider request, including rapid double taps and callable retries.
- Confirm provider status, amount (K50), currency (ZMW), and merchant transaction reference before granting access.
- Configure Firebase App Check before production; the callable currently relies on Firebase Authentication and server-side ownership checks while App Check rollout is pending.
- Verify Firestore rules prevent clients from creating or approving provider payment records and subscriptions.
- Run Flutter analyze/tests and Functions tests before merging/deploying.
- Never activate premium based on a screenshot, SMS text supplied by a user, or a payment-reference string alone.
