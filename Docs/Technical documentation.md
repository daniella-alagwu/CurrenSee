# CurrenSee — Technical Documentation

## 1. Purpose and scope

This document describes the current project structure and developer setup for CurrenSee. It is separate from the repository’s root README.md.

CurrenSee is a Flutter application with Firebase Authentication, a Node.js/Express API and a MySQL database. It also uses external services for foreign-exchange reference rates and financial-news headlines.

## 2. Architecture

flowchart LR
  App[Flutter app]
  Auth[Firebase Authentication]
  API[Node.js / Express API]
  SQL[(MySQL database)]
  FX[Frankfurter rate API]
  RSS[Google News RSS]
  FCM[Firebase Cloud Messaging]

  App -->|Sign up, sign in, verify email| Auth
  App -->|Firebase ID token in Bearer header| API
  API -->|Verify ID token / admin claim| Auth
  API --> SQL
  App -->|Latest rates and trend requests| FX
  API -->|Scheduled alert and digest checks| FX
  API -->|Refresh news feed| RSS
  API --> SQL
  API -->|Push messages| FCM
  FCM --> App


### Flutter application

- **lib/main.dart** — application entry point and app-level navigation/authentication setup.
- **lib/auth/** — authentication gate, email-verification flow, OTP screen and shared authentication widgets.
- **lib/screens/** — user screens for registration, login, conversion, rates, profile, history, alerts, notifications, news, support and administration.
- **lib/services/api_client.dart** — sends authenticated requests to the backend and attaches Firebase ID tokens.
- **lib/services/rates_service.dart** — calls the Frankfurter API directly for latest rates and a short historical trend.
- **lib/services/user_store.dart** — loads the signed-in user’s profile/preferences for display.
- **lib/services/notification_service.dart** and **notification_store.dart** — device push setup and in-app notification state.

The conversion screens use a local catalogue of 19 rate currencies, including NGN; ILS is not in that catalogue. Country information and the registration currency picker are supplied by Flutter packages and may offer additional currencies. Registration can insert a selected three-letter code into MySQL, but the converter still uses the fixed 19-code list; choosing a code outside that list may therefore not be usable for conversion. The rate data itself is obtained separately from Frankfurter.

### Backend

- **backend/server.js** — configures Express, JSON parsing, CORS, health routes, user/admin routes and the rate-watcher job.
- **backend/routes/** — endpoint definitions and middleware.
- **backend/controllers/** — authentication/profile, preferences, conversions, messages, notifications, admin users and news logic.
- **backend/middleware/authMiddleware.js** — verifies Firebase ID tokens and applies account-status checks.
- **backend/middleware/adminMiddleware.js** — restricts admin routes using Firebase custom claims.
- **backend/config/db.js** — creates the MySQL connection pool from environment variables.
- **backend/config/firebaseAdmin.js** — initializes Firebase Admin from a private service-account JSON file.
- **backend/jobs/rateWatcher.js** — periodically checks rate-alert thresholds and daily reference-rate changes.
- **backend/utils/notifier.js** — stores in-app notifications and sends push notifications to registered devices when configured.
- **backend/utils/mailer.js** — sends optional six-digit verification codes through Nodemailer and the configured SMTP provider.
- **backend/scripts/** — development-admin creation, role management and suspended-account maintenance scripts.

## 3. Authentication and data flow

1. A user registers or signs in using Firebase Authentication with email and password.
2. Firebase sends the email-verification link. The app also displays a six-digit-code path, which calls the backend and requires functioning SMTP configuration.
3. The app obtains a Firebase ID token and sends it as **Authorization: Bearer &lt;token&gt;** to protected API endpoints.
4. Express verifies that token with Firebase Admin. Admin endpoints additionally require the **admin** custom claim.
5. After verification, the app sends the profile fields to **POST /api/users/create**. The backend stores the Firebase UID, email, country and selected currency in MySQL and creates default preferences.
6. Passwords and Firebase authentication credentials remain under Firebase Authentication. MySQL stores the CurrenSee application profile and data.
7. The app reads or updates the signed-in user’s profile, preferences, conversion history, alerts, support messages and notifications through the API.

If Firebase account creation succeeds but the API or database is unavailable, the Firebase account may exist before its MySQL profile has been created. The app’s verification gate retries profile setup after email verification.

## 4. Hosting and configuration

The current deployment arrangement is a Node.js API hosted on Render and a MySQL database hosted by Clever Cloud. Keep all provider credentials in the respective platform’s private environment settings. Do not commit backend/.env, Firebase service-account JSON files, SMTP passwords or database passwords.

### Backend environment

**backend/config/env.js** loads **backend/.env** for local development. The backend needs:

| **PORT** | Port supplied by the host or used locally. |
| **DB_HOST** | MySQL server host. |
| **DB_USER** | MySQL username. |
| **DB_PASSWORD** | MySQL password. |
| **DB_NAME** | MySQL database/schema name. |
| **FIREBASE_SERVICE_ACCOUNT_PATH** | Path to the private Firebase Admin service-account JSON, resolved relative to the backend folder. |
| **SMTP_HOST**, **SMTP_PORT**, **SMTP_USER**, **SMTP_PASS** | SMTP settings for the optional six-digit OTP email path. |

The Firebase project used by the Admin service account must match the Firebase project used by the Flutter application. For a hosted service, make the service-account file available through the host’s private secret-file facility and set the path accordingly.

### Flutter API URL

**ApiClient** reads **API_BASE_URL** at build/run time. The default currently points to the hosted API. For local development, set it to the local API base with **/api** appended. For an Android emulator connecting to a server on the development computer, the usual host address is **http://10.0.2.2:5000/api**; a physical device needs a reachable LAN address, or use the deployed HTTPS API.

Example:

flutter run --dart-define=API_BASE_URL=https://your-api-host.example/api


The backend exposes **GET /health** for a simple service-health response and **GET /** for a plain “Backend running” response.

### Local run

From the project root:


flutter pub get


In a second terminal:


cd backend
npm install
npm run dev


Run the Flutter app with an API base address appropriate for the selected device. Firebase must be configured for the platforms being run; the repository contains **lib/firebase_options.dart** and the Android Firebase configuration file.

### Database setup and migrations

- **backend/database/schema.sql** describes the current tables and initial currency catalogue.
- On a brand-new database, apply the full schema once after selecting the correct MySQL database.
- The schema currently has a deployment-specific **USE** statement at the top. Before importing it into another database, change that statement to the target schema name or remove it and select the schema in the database client.
- The migration files are incremental changes for databases created from older versions. Do not run all migrations on top of a fresh schema; that can attempt to add columns and tables that already exist.
- Before migrating an existing database, back it up and apply only the migrations that are not already reflected in that database. Several older migration files contain **USE currensee**; adjust the selected schema for the actual environment before running them.

The migration folder includes country fields, NGN, admin/status fields, profile/support changes, notification-digest data and the primary-admin constraint. The current schema already contains these features.

## 5. Database model


| **users** | MySQL app profile linked to a Firebase UID; includes email, country, role, status, avatar and primary-admin flag. |
| **user_preferences** | Default currencies, notification preferences and daily digest date. |
| **currencies** | Currency code/name/symbol catalogue used for preferences and conversion records. |
| **conversion_history** | Saved input amount, pair, rate, result and timestamp. |
| **rate_alerts** | User-defined pair, threshold, direction, active state and trigger time. |
| **notifications** | In-app alert/system messages, read state and timestamp. |
| **device_tokens** | Firebase Cloud Messaging token associated with a user and platform. |
| **email_otp_codes** | Hashed OTP, expiry and failed-attempt count for the optional email-code flow. |
| **news_articles** | Cached article title, summary, source, URL and publication time. |
| **support_messages** | In-app support conversation messages between a user and admin. |
| **exchange_rates** | Rate/date storage structure present in the schema; current Flutter rate display fetches from Frankfurter directly. |
| **faqs, support_tickets, feedback** | Tables present in the schema; current API routes do not expose full FAQ or feedback/ticket workflows. |

The **users.firebase_uid** field links a MySQL profile to Firebase Authentication. Preferences, histories, alerts, notifications and support messages link to the MySQL **users.id** key.

## 6. API reference

All routes below are mounted under **/api**. Except for health/root routes, the routes listed here require a valid Firebase ID token. Admin routes additionally require the Firebase **admin** custom claim. User data is scoped to the authenticated Firebase UID.

### Health

| **GET** | **/health** | Health status JSON. |
| **GET** | **/** | Plain backend-running response. |

### User routes


| **POST** | **/users/create** | Create or update the MySQL profile and initial preferences. |
| **GET** | **/users/me** | Read current account profile/status. |
| **PATCH** | **/users/profile** | Update allowed profile fields. |
| **GET / PATCH** | **/users/preferences** | Read or update default currencies and notification preferences. |
| **POST** | **/users/conversions** | Validate and save a conversion; the backend calculates the stored result from amount and submitted rate. |
| **GET** | **/users/conversions** | Read conversion history with limit/offset pagination. |
| **POST** | **/users/otp/send** | Create and email a six-digit code; requires SMTP configuration. |
| **POST** | **/users/otp/verify** | Check the code and mark the Firebase email verified. |
| **GET / POST** | **/users/messages** | Read or send an in-app support message. |
| **POST** | **/users/suspension-appeal** | Send a support message tagged as a suspension appeal. |
| **GET / POST** | **/users/alerts** | List or create rate alerts. |
| **POST** | **/users/alerts/:id/delete** | Delete a rate alert. |
| **POST** | **/users/device-token** | Register a Firebase Messaging device token. |
| **POST** | **/users/device-token/remove** | Remove a device token. |
| **GET** | **/users/notifications** | List in-app notifications. |
| **POST** | **/users/notifications/read** | Mark notifications read. |
| **GET** | **/users/news** | Refresh/cache and return market-news articles. |

### Admin routes

| **GET** | **/admin/me** | Confirm admin identity. |
| **GET** | **/admin/stats** | Read dashboard counts. |
| **GET** | **/admin/users** | Search/list user profiles. |
| **GET** | **/admin/users/:id** | Read a user detail record. |
| **POST** | **/admin/users/:id/:action** | Perform an allowed user-management action such as suspend, unsuspend, promote, demote or delete. |
| **GET** | **/admin/messages/threads** | List support threads. |
| **GET** | **/admin/messages/threads/:userId** | Read one support conversation. |
| **POST** | **/admin/messages/threads/:userId** | Reply to a user. |
| **POST** | **/admin/announcements** | Send an administrator announcement. |

## 7. Exchange rates, alerts, news and notifications

The Flutter **RatesService** calls **https://api.frankfurter.dev/v2** for current reference rates and short trends. The app displays a subset of currencies; its catalogue and the database **currencies** table must be updated when adding a code. Frankfurter describes its data as daily reference rates from central banks and official sources; it is not an intraday transaction quote. See [Frankfurter](https://frankfurter.dev/).

The backend rate watcher calls Frankfurter’s v1 API on a 30-minute schedule to check saved thresholds and daily changes. The schedule is more frequent than the underlying daily rate publication; it does not make the source rate update every 30 minutes.

The news endpoint refreshes a Google News RSS search feed, stores/updates articles in **news_articles**, and returns the newest saved items. Articles open at their source.

The notification utility stores notifications in MySQL and sends Firebase Cloud Messaging pushes to registered device tokens when a user has push notifications enabled. Push delivery additionally depends on Firebase platform setup, notification permission and token registration.

## 8. Admin account management

Admin rights are granted through Firebase custom claims and mirrored into the MySQL **users.role** field. The API checks the Firebase claim; it does not trust a role supplied by the app’s registration form. The database schema allows only one primary admin.

For a real administrator, create the account through the app, verify its email and sign in once so its MySQL profile exists. From **backend**, grant the owner role with:


npm run admin:role -- admin@example.com owner


The script requires confirmation by typing the email. The account must be verified, its SQL profile must exist, Firebase Admin credentials must be configured, and the script must be able to reach both Firebase and MySQL.

A development-only seed is available for a test account ending in **.test**. It reads **ALLOW_DEV_ADMIN_SEED=true**, **DEV_ADMIN_EMAIL** and **ADMINPASS** from the private backend environment. It marks the test account verified and adds the admin claim in Firebase, but the account must still sign in through the app to create its MySQL profile. Never use this seed with a production Firebase project or commit its password.

## 9. Security and operational notes

- Never commit **backend/.env**, database credentials, SMTP credentials or Firebase Admin service-account JSON.
- Keep Firebase authentication credentials in Firebase; do not store passwords in MySQL.
- Require Firebase ID tokens on protected API calls and verify them on the server.
- Keep admin promotion/revocation in trusted backend scripts and admin-only routes.
- Use HTTPS for hosted app-to-API traffic.
- A MySQL profile can be missing even when a Firebase account exists; retry account setup after resolving API/database availability.
- The exchange-rate API may be unavailable, and its data is indicative. Display failures clearly and do not present a reference rate as a guaranteed transaction price.
- OTP email delivery depends on a valid SMTP service. If it is not configured for a deployment, use Firebase email verification links.
