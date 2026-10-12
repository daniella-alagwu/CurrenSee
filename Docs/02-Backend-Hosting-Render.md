# 02 - How We Hosted the Backend on Render

> **In one line:** The backend (Node.js + Express) runs on **Render**, so it is online 24/7 and the app does not depend on anyone's laptop.

**Live address:** `https://currensee-f0sf.onrender.com`
**Quick test:** open `https://currensee-f0sf.onrender.com/health` in a browser. You should see `{"status":"ok","service":"currency-backend"}`.

---

## 1. Why Render?

At the start, the backend ran on one teammate's computer and was shared with a **VS Code forwarded port**. That broke whenever the laptop slept, the internet changed, or VS Code closed. So we moved to hosted services:

| Part | Where it lives now |
|---|---|
| Backend API | **Render** (this file) |
| MySQL database | **Clever Cloud** ([04-Database-Structure.md](04-Database-Structure.md)) |
| Logins | **Firebase** |

Now anyone (teammates, graders) can use the app without our computers being on.

---

## 2. What Render needs to know

The backend code lives in the **`backend/`** folder of the GitHub repository. Render pulls it from GitHub and runs it.

| Render setting | Value |
|---|---|
| Service type | **Web Service** |
| Source | The project's GitHub repository |
| Root Directory | `backend` |
| Runtime | Node (version 18 or newer, because the code uses the built-in `fetch`) |
| Build Command | `npm install` |
| Start Command | `npm start` (this runs `node server.js`) |
| Health Check Path (optional) | `/health` |

The server listens on `process.env.PORT`. Render sets `PORT` by itself, so we do **not** add it.

**One hurdle we faced with render was the usage of free tier. Since the app goes to a loading screen if not in use for 15 minutes, we used Uptime Robot to keep sending requests to the hosted backend so it never stops running.**

---

## 3. Environment variables (the secret settings)

Passwords and keys must **never** be written in the code or pushed to GitHub. On Render we put them in **Environment** -> **Environment Variables**.

| Variable | What it is | Example (fake) |
|---|---|---|
| `DB_HOST` | Clever Cloud MySQL host | `xxxxx-mysql.services.clever-cloud.com` |
| `DB_USER` | MySQL username | `uXXXXXXXX` |
| `DB_PASSWORD` | MySQL password | *(secret)* |
| `DB_NAME` | Database name | `bsj6vi7c3gpqyz9nujvw` |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | Where Render stored the Firebase key file (see section 4) | `/etc/secrets/serviceAccountKey.json` |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS` | Email sending for the optional six-digit code. **Not working, can be left empty** | - |

The real values are in [06-Login-Credentials.md](06-Login-Credentials.md).

> The code only reads `DB_HOST`, `DB_USER`, `DB_PASSWORD` and `DB_NAME`. It does **not** read a `DB_PORT`, so it uses MySQL's normal port `3306`.

---

## 4. The Firebase key file

**Firebase was added to this project solely for email verification purposes since render blocks smtp mail sending**

The backend needs a **service-account JSON file** from Firebase to check login tokens. It is like a master key, so it is **not** in GitHub (it is listed in `.gitignore`).

How we gave it to Render:

1. Firebase Console -> **Project settings** -> **Service accounts** -> **Generate new private key**. This downloads a `.json` file.
2. In Render -> **Environment** -> **Secret Files** -> add a file named `serviceAccountKey.json` and paste the file's contents.
3. Render places secret files in `/etc/secrets/`, so set `FIREBASE_SERVICE_ACCOUNT_PATH` to `/etc/secrets/serviceAccountKey.json`.

The Firebase project of this key **must be the same** project the Flutter app uses (`currensee-6633a`). If they differ, every login will fail with "Invalid or expired token".

---

## 5. Steps to deploy from scratch

1. Push the project to GitHub (make sure `.env` and the Firebase key file are **not** included).
2. Create the MySQL database on Clever Cloud and run `Docs/database/currensee_full_schema.sql` on it.
3. On Render click **New +** -> **Web Service** -> connect the GitHub repo.
4. Fill in the settings from section 2.
5. Add the environment variables (section 3) and the secret file (section 4).
6. Click **Create Web Service**. Render builds and starts it. Watch the **Logs** tab until you see `Server running on port ...`.
7. Open `<your-render-url>/health` to confirm.
8. Put the Render address in the Flutter app. It is set in `lib/services/api_client.dart` (it ends with `/api`):

```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://currensee-f0sf.onrender.com/api',
);
```

From then on, every push to the connected GitHub branch can redeploy automatically (if auto-deploy is on).

---

## 6. Things to know when testing

- **The first request can be slow.** On Render's free plan a service that has not been used for a while goes to sleep, and the next request can take up to about a minute to wake it. If the app says the backend is unreachable, wait a minute and try again. Opening `/health` first wakes it up.
- **Logs.** Render -> your service -> **Logs** shows every request (`GET /api/users/me 200 35ms`) and errors. This is the first place to look when something fails.
- **The rate watcher runs inside the same service.** It starts 15 seconds after the server starts and then runs every 30 minutes. If the service is asleep it is paused too, so alert notifications can be delayed.

---

## 7. Common problems

| Problem | Likely cause | Fix |
|---|---|---|
| Render deploy fails with `FIREBASE_SERVICE_ACCOUNT_PATH is missing` | Variable not set | Add it in Environment |
| `Firebase service account file not found` | Wrong path or secret file not added | Check section 4 |
| Every request returns `401 Invalid or expired token` | Firebase key is from a different project than the app | Use the key from `currensee-6633a` |
| `ECONNREFUSED` / `Access denied for user` in logs | Wrong DB host, user or password | Re-copy them from the Clever Cloud dashboard |
| `Too many connections` / `max_user_connections` | Database plan allows few connections | Lower `connectionLimit` in `backend/config/db.js` |
| App says backend unreachable | Service asleep or crashed | Open `/health`, wait, check Logs |
