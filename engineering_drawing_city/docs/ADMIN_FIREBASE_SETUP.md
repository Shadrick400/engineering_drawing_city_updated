# Firebase administrator setup

The app no longer contains a hardcoded administrator password or a local password bypass. Administrator sign-in must use Firebase Authentication.

## One-time setup

1. Open the Firebase Console for project `engineering-drawing-city-5dd6f`.
2. Open **Authentication → Users** and create or reset the administrator's email/password account. Use the intended administrator email and set a new, unique password. Do not reuse a password that was previously committed to Git.
3. Copy the Firebase Authentication user's UID.
4. Open **Firestore Database** and create a document in the `users` collection whose document ID is exactly that UID.
5. Set the document fields to match the user profile model. At minimum:
   - `uid`: the Firebase Authentication UID
   - `email`: the administrator email
   - `name`: the administrator display name
   - `role`: `admin`
   - `isSuspended`: `false`
   - `createdAt`: Firestore timestamp
   - `updatedAt`: Firestore timestamp
6. Keep the administrator's role assignment restricted to the Firebase Console or trusted server-side administration. Do not add an in-app feature that lets a user set their own role.
7. Sign in through the app's administrator login screen. If the Firestore profile is missing or its role is not `admin`, the app should reject the administrator sign-in rather than create a student profile.

## Important security cleanup

- A previous version of the repository contained a hardcoded administrator password. Removing it from the latest source does **not** erase it from Git commit history.
- Change that password immediately if it was ever real or reused.
- Consider making the repository private and removing the exposed secret from Git history with a carefully planned history rewrite. Back up the repository and coordinate any force-push before doing this.
- Do not put Firebase service-account keys, payment gateway secrets, or other private credentials in Flutter source code.
- Deploy the supplied Firestore and Storage rules only after reviewing them against the live Firebase collections and testing both student and administrator flows.


## Deploy the access-control rules

From the Flutter app directory, after confirming the Firebase CLI is using the intended project, deploy the rules:

```bash
firebase use engineering-drawing-city-5dd6f
firebase deploy --only firestore:rules,storage --project engineering-drawing-city-5dd6f
```

The rules now make the course catalogue metadata readable, but require an active subscription or the administrator role to read video, book and past-paper records. Files under `learning_materials/` in Firebase Storage use the same access check. Profile images are limited to their owner and administrators.

Upload book and past-paper PDFs into the Firebase Storage `learning_materials/` folder. In the admin form, use the private `gs://bucket/learning_materials/file.pdf` reference (not a public download-token URL). The in-app viewer retrieves the PDF through the authenticated Firebase Storage SDK; arbitrary public PDF websites are not accepted.

When an administrator signs in, the app converts legacy subscription date strings to Firestore timestamps so the expiry checks in the rules can work. New subscription records are saved as Firestore timestamps automatically.

## Video access limitation

Video lesson records are now read from Firestore only by administrators and active subscribers. The player embeds YouTube inside the app, but an **unlisted YouTube video is not DRM-protected**: a subscriber who obtains the video URL can still share it, and screen recording cannot be reliably prevented. Do not advertise unlisted YouTube as complete copy protection. If strict per-user playback control is required later, move premium videos to a private streaming service that supports signed playback URLs and access revocation.

## Firebase Storage billing prerequisite

As of 3 February 2026, Firebase Cloud Storage requires the project to use the Blaze pay-as-you-go plan, even though eligible no-cost usage quotas remain available on Blaze. A billing account must be linked to access Storage buckets. Before using the private PDF workflow, check the project's plan in Firebase Console → Usage and billing. Do not upgrade without the account owner's approval; configure budget alerts first. If the project must remain on Spark with no billing account, pause this Storage-based PDF workflow and choose a different private file-hosting solution before deploying the new Storage rules.
