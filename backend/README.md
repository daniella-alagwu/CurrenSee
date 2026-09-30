# CurrenSee backend setup

## Create a development admin without an inbox

For a school-project development Firebase project, you can create one dedicated test admin with a password you choose:

1. In your private local `.env`, set `ALLOW_DEV_ADMIN_SEED=true`, `DEV_ADMIN_EMAIL=admin@currensee.test`, and `DEV_ADMIN_PASSWORD` to a unique password with at least 12 characters.
2. From this folder, run `npm run admin:create:dev`.
3. Sign in through the Flutter app with those credentials. When the backend is reachable, the app creates the MySQL profile and routes to the admin placeholder.

This script creates a Firebase account, sets its emailVerified flag for testing, and assigns the admin custom claim. It does not send or verify email. The address must end in `.test`; that domain has no inbox. It refuses to run when `NODE_ENV=production` or unless `ALLOW_DEV_ADMIN_SEED=true` is set. Use only a development Firebase project, and keep the password and service-account key private.

## What this backend handles

- Verifies Firebase ID tokens sent by the Flutter app.
- Stores a user's Firebase UID, email, country, and chosen default currency in MySQL.
- Sends a six-digit email code through Nodemailer and marks the Firebase account verified when the code is correct.
- Creates default user preferences after registration.

The Flutter app creates the Firebase account, calls `POST /api/users/create` with the country and currency, then asks Firebase to send a verification link. The verification screen also offers the NodeMailer OTP option. After either option verifies the email, the app calls `/api/users/create` again to make sure the SQL profile exists, then opens the placeholder home screen.

## Setup

1. Install MySQL and create/apply `database/schema.sql` for a new database. If the `users` table already exists, apply `database/migrations/001_add_user_country.sql` once.
2. Copy `.env.example` to `.env` and fill in the MySQL and SMTP values. Keep `.env` private.
3. In Firebase Console, open **Project settings → Service accounts → Generate new private key**. Save the downloaded JSON as `backend/serviceAccountKey.json`. Keep it private and do not commit it.
4. From this folder, run `npm install`, then `npm run dev`.
5. Confirm the server responds at `http://localhost:5000/`. The Android emulator uses `http://10.0.2.2:5000/api` to reach the host computer.

## Auth endpoints

- `POST /api/users/create` — authenticated with a Firebase bearer token; creates or updates the SQL profile and default currency.
- `POST /api/users/otp/send` — authenticated; sends a 6-digit code that expires after 10 minutes.
- `POST /api/users/otp/verify` — authenticated; checks the code and marks the Firebase email verified.
- `GET /api/users/me` — authenticated; returns the signed-in user's stored profile and default currency preferences. Returns `404 PROFILE_NOT_FOUND` until `/api/users/create` has stored the profile.

Firebase Email/Password sign-in must be enabled in Firebase Authentication. OTP delivery will not work until valid SMTP host, port, username, and password values are configured.

## User preferences and conversion history

These endpoints require `Authorization: Bearer <Firebase ID token>`. They only read or modify data belonging to the signed-in user.

- `GET /api/users/preferences` — returns the user's default base/target currencies and notification settings.
- `PATCH /api/users/preferences` — updates any supplied fields: `defaultBaseCurrency`, `defaultTargetCurrency`, `pushEnabled`, and `alertNotificationsEnabled`.
- `POST /api/users/conversions` — saves a conversion. JSON body: `{"fromCode":"USD","toCode":"EUR","amount":"25.00","rateUsed":"0.92000000"}`. The server calculates and stores the result. The rate is currently supplied by the app; connect it to the exchange-rate service when that backend is available.
- `GET /api/users/conversions?limit=50&offset=0` — returns the signed-in user's conversion history, newest first. The maximum page size is 100.

## Admin access

Admin access uses the Firebase custom claim \`admin: true\`. Do not add an admin flag to registration input or expose an endpoint that lets users promote themselves.

1. Create the intended admin account through the app and verify its email.
2. From this backend folder, grant the role using the account's email:

   \`\`\`sh
   npm run admin:role -- admin@example.com
   \`\`\`

   The script looks up the verified Firebase account, asks you to type the email again, and then sets the custom claim. It preserves the account's other custom claims. To revoke the role, add \`revoke\`:

   \`\`\`sh
   npm run admin:role -- admin@example.com revoke
   \`\`\`

3. Have that account sign out and back in. The app refreshes its Firebase token and routes admins to \`lib/screens/admin/admin_home.dart\`.

The backend protects \`GET /api/admin/me\` with both authentication and the admin claim. It confirms that the signed-in user has admin access; it is not yet an admin data-management API. Add each future admin endpoint behind \`requireAuth\` and \`requireAdmin\`.

The simple Admin home is a placeholder for the front-end teammate to expand. Keep the Firebase Admin service-account key and \`.env\` private; the role-grant command runs locally using that key and is not an API exposed to app users.
## User Profile, Preferences, and Conversion History

The backend provides Firebase-authenticated endpoints for a user’s profile, preferences, and conversion history. Each request uses the signed-in user’s Firebase ID token, and users can access only their own data.

- `GET /api/users/me` — returns the user’s saved email, name, country, and currency preferences.
- `GET /api/users/preferences` — retrieves the user’s default currencies and preference settings.
- `PATCH /api/users/preferences` — updates supplied currency or preference settings.
- `POST /api/users/conversions` — saves a conversion and calculates its result from the submitted amount and rate.
- `GET /api/users/conversions` — returns the user’s conversion history, newest first, with optional `limit` and `offset` pagination.

Flutter’s `ApiClient` includes methods for calling these endpoints: `getCurrentUser`, `getPreferences`, `updatePreferences`, `saveConversion`, and `getConversionHistory`.

The conversion rate is currently provided by the calling app. The rate service can be connected when it is available. The backend endpoints and Flutter API methods are ready for the frontend screens to use.