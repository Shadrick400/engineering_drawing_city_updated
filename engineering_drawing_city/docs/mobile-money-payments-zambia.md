# Engineering Drawing City — Zambia mobile-money payments

The student profile subscription card now offers an assisted mobile-money payment flow for the K50 / 30-day subscription.

## Payment numbers configured by the project owner

- Airtel Money: 0969262568
- MTN MoMo: 0777365872

The app displays the selected number, lets the student copy it, and asks for the transaction ID from the successful wallet confirmation. A pending payment record is saved through the existing Firestore payment service.

## Verification and access

This is an assisted/manual mobile-money collection flow, not a direct carrier API integration or automatic wallet prompt. A payment remains pending until an administrator verifies it through the existing payment review workflow. Only the trusted admin approval path activates the subscription.

Do not activate premium access based on the user's self-reported transaction ID alone. Never ask for or store wallet PINs, OTPs, or other authentication secrets.

## Future direct integration

For automatic checkout, Engineering Drawing City will need official merchant/collection accounts and approved Airtel Money and MTN MoMo API credentials. Those credentials must be stored in Firebase Functions secrets or another server-side secret manager. The server must verify provider transaction status and amount before approving the payment and activating the subscription.
