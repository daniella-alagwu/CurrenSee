# 01 - API List

> **What is an API?** A way for one program to ask another program for something. Example: our app asks the Frankfurter API "how many euros is 1 dollar today?" and it replies with a number.

CurrenSee uses **two kinds** of APIs:

1. **Our own API** - the backend we built (Node.js + Express). Hosted on Render. See [02-Backend-Hosting-Render.md](02-Backend-Hosting-Render.md).
2. **Outside APIs** - services made by other companies that we plug into.

---

## Part A - Outside APIs we use

| # | Service | What we use it for | Who calls it | Needs an API key? |
|---|---|---|---|---|
| 1 | **Firebase Authentication** | Sign up, log in, email verification link, password reset, Google sign-in | Flutter app (and backend checks the login token) | Yes, built into the Firebase setup (`lib/firebase_options.dart`) |
| 2 | **Firebase Admin SDK** | Backend checks that a login token is real, reads the `admin` badge, suspends/deletes accounts | Backend | Yes, a private service-account file (never shared) |
| 3 | **Firebase Cloud Messaging (FCM)** | Push notifications to phones | Backend sends, app receives | Same Firebase project |
| 4 | **Frankfurter API v2** - `https://api.frankfurter.dev/v2` | Current exchange rates and the small history trend line | Flutter app | No |
| 5 | **Frankfurter API v1** - `https://api.frankfurter.dev/v1` | Backend checks rate alerts and creates the daily rate update | Backend (every 30 minutes) | No |
| 6 | **Google News RSS** - `news.google.com/rss/search?q=currency exchange OR forex market` | Currency news headlines | Backend | No |
| 7 | **SMTP email (Nodemailer)** | Sends the optional six-digit email code | Backend | **Not working any more** in our hosted setup. Firebase's email link is used instead |

### Details for each outside API

**Frankfurter (exchange rates)**
- Free, no sign-up. Rates come from central banks (the European Central Bank and others).
- Rates are **updated once per working day**. They are *reference* rates, not live second-by-second prices. Banks and exchange shops may show different numbers.
- The app calls `GET /v2/rates?base=USD&quotes=EUR,GBP,...` for the latest rates, and the same endpoint with a `from=` date for the trend line.
- The backend calls `GET /v1/latest?base=USD&symbols=NGN` (alerts) and `GET /v1/<date>..?base=USD&symbols=EUR` (daily update).
- Our app only offers the **19 currencies** listed in the database doc, even though Frankfurter has more.

**Firebase Authentication**
- Sign-in methods enabled: **Email/Password** and **Google**.
- After login, Firebase gives the app a **token** (like a temporary ID card). The app sends that token to our backend on every request.

**Google News RSS**
- The backend downloads the feed, saves up to 30 articles in the `news_articles` table, and returns the newest ones. If Google is unreachable, it returns the saved ones.

---

## Part B - Our own backend API

**Base address (live):** `https://currensee-f0sf.onrender.com`
**All app routes start with:** `/api`

### How requests are protected

| Label | Meaning |
|---|---|
| **Public** | No login needed |
| **Login** | Needs the header `Authorization: Bearer <Firebase token>` |
| **Login + Active** | Same as Login, and the account must **not** be suspended |
| **Admin** | Login **and** the account has the Firebase `admin` badge |

Errors always look like this:
```json
{ "error": { "code": "INVALID_AMOUNT", "message": "Amount must be positive with at most 4 decimal places." } }
```

### B1. Health check

| Method | Route | Access | What it does |
|---|---|---|---|
| GET | `/` | Public | Returns the text `Backend running` |
| GET | `/health` | Public | Returns `{"status":"ok","service":"currency-backend"}` |

**Quick test:** open `https://currensee-f0sf.onrender.com/health` in a browser.

### B2. Account and profile

| Method | Route | Access | What it does |
|---|---|---|---|
| POST | `/api/users/create` | Login + Active | Creates (or updates) the user's row in MySQL and their default preferences. Body: `countryCode`, `countryName`, `currencyCode`, optional `name` |
| GET | `/api/users/me` | Login | Returns the profile, status and preferences. Returns `404 PROFILE_NOT_FOUND` if the MySQL row does not exist yet |
| PATCH | `/api/users/profile` | Login + Active | Changes `name`, country, or `avatar` |
| POST | `/api/users/restore-signin` | Public | Used by the suspended-account flow so a suspended user can sign in and see the suspended page |
| POST | `/api/users/otp/send` | Login + Active | Emails a six-digit code (**needs SMTP, not working**) |
| POST | `/api/users/otp/verify` | Login + Active | Checks the code and marks the email verified |

### B3. Preferences

| Method | Route | Access | What it does |
|---|---|---|---|
| GET | `/api/users/preferences` | Login + Active | Returns default currencies and notification switches |
| PATCH | `/api/users/preferences` | Login + Active | Updates `defaultBaseCurrency`, `defaultTargetCurrency`, `pushEnabled`, `alertNotificationsEnabled` |

### B4. Conversions

| Method | Route | Access | What it does |
|---|---|---|---|
| POST | `/api/users/conversions` | Login + Active | Saves a conversion. Body: `{"fromCode":"USD","toCode":"EUR","amount":"25.00","rateUsed":"0.92"}`. The backend works out `result` itself |
| GET | `/api/users/conversions?limit=50&offset=0` | Login + Active | Conversion history, newest first (max 100 per page) |

### B5. Rate alerts

| Method | Route | Access | What it does |
|---|---|---|---|
| GET | `/api/users/alerts` | Login + Active | Lists the user's alerts |
| POST | `/api/users/alerts` | Login + Active | Creates one. Body: `baseCode`, `targetCode`, `threshold`, `direction` (`ABOVE`/`BELOW`). Max 20 active |
| POST | `/api/users/alerts/:id/delete` | Login + Active | Deletes one of the user's own alerts |

### B6. Notifications and devices

| Method | Route | Access | What it does |
|---|---|---|---|
| GET | `/api/users/notifications` | Login + Active | Last 100 notifications plus the unread count |
| POST | `/api/users/notifications/read` | Login + Active | Marks all as read |
| POST | `/api/users/device-token` | Login + Active | Saves the phone's push token. Body: `token`, `platform` (`android`/`ios`) |
| POST | `/api/users/device-token/remove` | Login + Active | Removes a push token (used on log out) |

### B7. News

| Method | Route | Access | What it does |
|---|---|---|---|
| GET | `/api/users/news?limit=20` | Login + Active | Refreshes the news feed, then returns the newest articles (max 50) |

### B8. Support chat (works even for suspended users)

| Method | Route | Access | What it does |
|---|---|---|---|
| GET | `/api/users/messages` | Login | The user's chat with the admin |
| POST | `/api/users/messages` | Login | Sends a message. Body: `body` |
| POST | `/api/users/suspension-appeal` | Login | Sends a message marked as an appeal |

### B9. Admin routes

| Method | Route | Access | What it does |
|---|---|---|---|
| GET | `/api/admin/me` | Admin | Confirms the caller is an admin |
| GET | `/api/admin/stats` | Admin | Dashboard numbers: total users, new this week, suspended, admins, unread messages |
| GET | `/api/admin/users?q=&limit=&offset=` | Admin | Search and list users |
| GET | `/api/admin/users/:id` | Admin | One user's details and counts |
| POST | `/api/admin/users/:id/:action` | Admin | `action` is one of `suspend`, `unsuspend`, `promote`, `demote`, `delete` |
| GET | `/api/admin/messages/threads` | Admin | All support conversations |
| GET | `/api/admin/messages/threads/:userId` | Admin | One conversation |
| POST | `/api/admin/messages/threads/:userId` | Admin | Admin replies to a user |
| POST | `/api/admin/announcements` | Admin | Sends a notification to all users. Body: `title`, `body` |

**Admin safety rules built into the code:**
- You cannot suspend, delete or demote **yourself**.
- Only the **primary admin** can promote or demote other admins.
- The primary admin cannot be changed from the app.

### B10. Background job (not a route)

`backend/jobs/rateWatcher.js` runs **15 seconds after the server starts, then every 30 minutes**. Each run it:
1. Checks every active rate alert. If the target is reached, it switches the alert off, creates a notification and sends a push.
2. Sends each user a **daily rate update** for their default pair (once per day).

---

## Part C - Where the app uses each route

The Flutter file `lib/services/api_client.dart` is the single place that talks to our backend. Each button in the app ends up calling one of its methods (`saveConversion`, `createAlert`, `getNotifications`, `getNews`, and so on). The base address is set in that file and can be changed at build time:

```
flutter run --dart-define=API_BASE_URL=https://currensee-f0sf.onrender.com/api
```

**Totals:** 7 outside services, and 32 backend routes (2 health + 21 user + 9 admin). A `GET` and a `PATCH` on the same path count as two routes.
