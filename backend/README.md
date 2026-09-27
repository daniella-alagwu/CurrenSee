# CurrenSee backend setup

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
