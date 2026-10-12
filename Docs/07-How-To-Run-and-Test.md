# 07 - How to Run and Test CurrenSee

Pick the option that fits you.

| Option | For who | Time | Needs |
|---|---|---|---|
| **A. Quick test** | Markers who just want to see the app working | 5 min | Flutter or the APK |
| **B. Test the backend only** | Checking the API | 2 min | A web browser |
| **C. Full local copy** | Developers who want everything on their own computer | 30+ min | Node, MySQL, Firebase key |

---

## Option A - Quick test (uses our hosted backend and database)

You do **not** need to set up a database or backend. The app already points to our hosted backend (`https://currensee-f0sf.onrender.com/api`).

1. Install **Flutter** (Dart 3.12 or newer) and a phone/emulator, or Chrome.
2. In the project folder run:
   ```
   flutter pub get
   flutter run
   ```
3. Sign in with the accounts in [06-Login-Credentials.md](06-Login-Credentials.md).

**If an APK file is included in the submission,** install it on an Android phone instead and skip steps 1-2.

**Make an APK yourself:** `flutter build apk --release` -> the file appears in `build/app/outputs/flutter-apk/app-release.apk`.

### A quick test script (5 minutes)

| # | Do this | You should see |
|---|---|---|
| 1 | Open `/health` link in a browser and wait | `{"status":"ok",...}` |
| 2 | Open the app | Animated splash, then the Welcome screen |
| 3 | Sign in as the **normal user** | Home screen with rates |
| 4 | Convert tab -> USD to NGN, amount 100 -> **Convert Now** | The result shows and a message says "Conversion saved to your history." |
| 5 | Home -> **Saved Pairs** | Your conversion in history |
| 6 | Bell icon -> alerts -> create an alert | The alert appears in the list |
| 7 | Home -> **Market News** | Currency headlines |
| 8 | Side menu -> **Contact** -> send a message | The message appears in the chat |
| 9 | Log out, sign in as **admin** | Admin home with statistics |
| 10 | Admin -> Inbox | The message from step 8; reply to it |
| 11 | Admin -> Users -> open the normal user | Suspend, then unsuspend |

---

## Option B - Test the backend only

Open in a browser:

| Link | Expected |
|---|---|
| `https://currensee-f0sf.onrender.com/` | `Backend running` |
| `https://currensee-f0sf.onrender.com/health` | `{"status":"ok","service":"currency-backend"}` |
| `https://currensee-f0sf.onrender.com/api/users/me` | `401` "Missing Authorization header" (this is **correct**: the route is protected, so it proves login protection works) |

All other routes need a Firebase login token, so they are easiest to test through the app. The full list is in [01-API-List.md](01-API-List.md).

---

## Option C - Full local copy

You need: **Node.js** (22.15 or newer for `npm run dev`; 18+ is enough for `npm start`), **MySQL**, **Flutter**, and a **Firebase project**.

### C1. Database
1. Create an empty MySQL database, for example `currensee`.
2. Run `Docs/database/currensee_full_schema.sql` on it once.

### C2. Backend
```
cd backend
npm install
```
1. Copy `.env.example` to `.env` and fill in:
   ```
   PORT=5000
   DB_HOST=<database host>
   DB_USER=<database password>
   DB_PASSWORD=<mysql password>
   DB_NAME=currensee
   FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json
   ```
   The `SMTP_` lines can stay as they are (email codes do not work, the app uses Firebase's link).
2. In Firebase Console -> **Project settings** -> **Service accounts** -> **Generate new private key**. Save the file as `backend/serviceAccountKey.json`.
3. In Firebase Console -> **Authentication** -> **Sign-in method**, enable **Email/Password** (and **Google** if you want Google sign-in).
4. Start it:
   ```
   npm run dev
   ```
   (If you get a "bad option: --use-system-ca" error, use `npm start`.)
5. Open `http://localhost:5000/health`.

> The Firebase key must come from the **same Firebase project** the Flutter app uses. The app is configured for project `currensee-6633a`. To use your own Firebase project, run `flutterfire configure` to regenerate `lib/firebase_options.dart`, and replace `android/app/google-services.json`.

### C3. Flutter app pointing at your local backend
```
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
```
- `10.0.2.2` is how an **Android emulator** reaches your computer.
- A **real phone** needs your computer's network address instead, e.g. `http://192.168.1.20:5000/api`.
- Chrome / desktop can use `http://localhost:5000/api`.

### C4. Make your own admin
Admins are made in Firebase, not in the app.

**Quick development admin** (only for a test Firebase project):
1. In `backend/.env` add:
   ```
   ALLOW_DEV_ADMIN_SEED=true
   DEV_ADMIN_EMAIL=admin@currensee.test
   ADMINPASS=<a password of at least 12 characters>
   ```
   (The script reads `ADMINPASS`. The older backend README calls it `DEV_ADMIN_PASSWORD`, but the script uses `ADMINPASS`.)
2. Run `npm run admin:create:dev`. The email must end in `.test`. It is created already verified, so no inbox is needed.
3. Sign in to the app once with that email and password. This creates its MySQL row.

**Make a real user an admin:**
```
npm run admin:role -- someone@example.com            # normal admin
npm run admin:role -- someone@example.com owner      # primary (owner) admin
npm run admin:role -- someone@example.com revoke     # remove admin
```
The person must have verified their email and signed in once. The script asks you to type the email to confirm. Afterwards the person must **sign out and in again**.

There can be **only one primary admin**. Only the primary admin can promote or demote other admins.

---

## Common problems

| Problem | Fix |
|---|---|
| App says backend is unreachable | Hosted backend may be asleep. Open `/health`, wait about a minute, retry |
| `Invalid or expired token` on every request | The Firebase key and the app are from different Firebase projects |
| Login works but "profile not found" | The MySQL row is missing. Sign out and in again; the app recreates it |
| Rates will not load | The Frankfurter service may be down, or no internet |
| Emulator cannot reach local backend | Use `10.0.2.2`, not `localhost` |
| Verification email not arriving | Check Spam/Junk, then use **Resend verification link** |
