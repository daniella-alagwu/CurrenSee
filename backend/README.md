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

Firebase Email/Password sign-in must be enabled in Firebase Authentication. OTP delivery will not work until valid SMTP host, port, username, and password values are configured.

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
