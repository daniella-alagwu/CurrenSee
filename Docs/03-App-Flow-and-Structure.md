# 03 - App Flow and Structure

> **In one line:** A Flutter app talks to Firebase (for login) and to our Node.js backend (for data). The backend stores data in MySQL.

---

## 1. The big picture

```
   +-----------------+        login / sign up         +----------------------+
   |                 | -----------------------------> | Firebase             |
   |   Flutter app   |  <---- token (ID card) ------- | Authentication       |
   |   (the phone)   |                                +----------------------+
   |                 |
   |                 |   request + token              +----------------------+      +--------------------+
   |                 | -----------------------------> | Backend (Render)     | ---> | MySQL              |
   |                 | <------- answer -------------- | Node.js + Express    | <--- | (Clever Cloud)     |
   |                 |                                +----------------------+      +--------------------+
   |                 |                                   |        |       |
   |                 |                                   |        |       +--> Google News RSS (headlines)
   |                 |   latest rates + trend            |        +--> Frankfurter API (rates, for alerts)
   |                 | --------------------------------> Frankfurter API
   +-----------------+                                   +--> Firebase Cloud Messaging (push to phone)
```

**Three rules to remember:**
1. **Firebase** handles passwords and "who are you?".
2. **The backend** handles our own data and checks the token on every request.
3. **The app** asks Frankfurter for rates directly (the backend does not sit in the middle for that).

---

## 2. User journey (what the user sees)

```
 Splash screen (animated logo)
        |
        v
 Welcome screen --------------------------+
   |                  |                   |
 "Create An Account"  "I already have     (Google sign-in
   |                   an account"         on either screen)
   v                  v                   |
 Register screen    Login screen <--+     |
   |                  |             |     |
   |                  +-- Forgot password? -> reset email
   v                  |
 Verify email  <------+  (only if the email is not verified yet)
   |
   v
 Complete profile (Google users only: country + currency)
   |
   v
 Is the account suspended? --yes--> Suspended screen (can send an appeal)
   |no
   v
 Is the user an admin? --yes--> Admin home (can switch to "User mode")
   |no
   v
 MAIN APP  (bottom tabs)
   Home | Rates | Convert | Settings (opens the side menu)
```

### The main app

| Screen | File | What the user does |
|---|---|---|
| **Home** | `screens/home/home_screen.dart` | Quick convert, short trend line, shortcut buttons (**Converter**, **Rate Trends**, **Saved Pairs**, **Market News**), bell icon, profile picture |
| **Rates** | `screens/rates_screen.dart` | Browse the latest rates for the 19 currencies |
| **Convert** | `screens/convert_screen.dart` | Pick two currencies, type an amount, see the result, **Convert Now** saves it to history |
| **Settings** (4th tab) | `screens/home/widgets/app_menu_drawer.dart` | Opens the side menu: Profile settings, About us, User guide, Transaction limits, Contact, Log out |
| **Profile** (tap your picture) | `screens/profile_screen.dart` | Your profile page |
| **Conversion history** (Home -> **Saved Pairs**) | `screens/home/conversion_history_screen.dart` | Past conversions with date, rate, amounts |
| **Notifications** (bell icon) | `screens/notifications_screen.dart` | In-app inbox, mark as read, and the way into Rate alerts |
| **Rate alerts** (from Notifications) | `screens/rate_alerts_screen.dart` | Create / delete alerts ("tell me when USD/NGN is above ...") |
| **News** (Home -> **Market News**) | `screens/news/news_screen.dart` | Currency headlines, tap to read at the source |
| **Contact** (side menu, normal users only) | `screens/menu/contact_screen.dart` | Chat with the admin (this is also our feedback / help channel) |
| **Profile settings** (side menu) | `screens/menu/profile_settings_screen.dart` | Change name, country, picture, default currencies, notification switches |
| **Transaction limits** (side menu) | `screens/menu/transaction_limits_screen.dart` | **Demo screen:** it shows sample figures, not real data |

### The admin side

| Screen | File | What the admin does |
|---|---|---|
| Admin home | `screens/admin/admin_home.dart` | See stats (users, new this week, suspended, admins, unread messages) |
| Users | `screens/admin/admin_users_screen.dart` | Search users, open one, suspend / unsuspend / promote / demote / delete |
| User detail | `screens/admin/admin_user_detail_screen.dart` | One user's information |
| Inbox | `screens/admin/admin_inbox_screen.dart` | Read and reply to support messages |

---

## 3. Flow 1: Sign up and first login

```
1. User fills the Register form (email, password, country, currency)
2. App  -> Firebase: create account            (Firebase sends a verification email)
3. App  -> Backend:  POST /api/users/create    (saves country + currency in MySQL)
4. User opens the email link
5. App checks every 3 seconds if the email is now verified
6. Verified -> App asks backend GET /api/users/me -> profile found
7. App opens the main app
```

**If step 3 failed** (backend asleep, no internet) the Firebase account exists but the MySQL row does not. That is fine: after verification the app asks for the profile, gets "not found", and creates it again automatically (`email_verification_gate.dart`). Google users go through `complete_profile_screen.dart` to pick their country and currency.

## 4. Flow 2: Every normal request

```
App                          Backend                       MySQL
 |  1. get fresh token         |                             |
 |  (from Firebase)            |                             |
 |  2. request + token  ---->  |                             |
 |                             | 3. verify token (Firebase)  |
 |                             | 4. check not suspended ---> |
 |                             | 5. run the query ---------> |
 |  <---- 6. answer ---------  | <------------------------- |
```

The token step is done by `middleware/authMiddleware.js` (login) and `middleware/adminMiddleware.js` (admin badge).

## 5. Flow 3: Convert and save

```
1. User picks USD -> NGN and types 100
2. App asks Frankfurter for the rate        (RatesService)
3. App shows: 100 USD = X NGN                (instant, on the phone)
4. User taps "Convert Now"
5. App -> Backend: POST /api/users/conversions { fromCode, toCode, amount, rateUsed }
6. Backend validates, calculates result = amount x rate, saves it in conversion_history
7. History screen reads it with GET /api/users/conversions
```

## 6. Flow 4: Rate alert -> notification

```
1. User creates an alert: USD/NGN ABOVE 1600        -> saved in rate_alerts
2. Every 30 min the backend job asks Frankfurter for the latest rate
3. If rate >= 1600:  alert switches off, a row goes into notifications
4. Backend also sends a push through Firebase Cloud Messaging (if the phone is registered
   and push is turned on in the user's settings)
5. The user sees the push, and the bell icon shows the new notification
```

## 7. Flow 5: Support chat and suspension

```
Normal user:     Contact screen  -> POST /api/users/messages        -> support_messages
Admin:           Admin inbox     -> GET  /api/admin/messages/threads
                                  -> POST /api/admin/messages/threads/:userId (reply)

Suspension:      Admin taps "Suspend" -> users.status = SUSPENDED
                 User sees the Suspended screen -> can only send an appeal
                 Admin taps "Unsuspend" -> user can use the app again
```

---

## 8. Project folder structure

```
CurrenSee/
├── lib/                          <- The Flutter app (Dart)
│   ├── main.dart                 App starts here: starts Firebase, shows splash
│   ├── firebase_options.dart     Firebase connection settings (generated)
│   ├── auth/                     Login gate, email verification, complete-profile, Google button
│   ├── screens/                  All screens (home, auth, menu, news, admin ...)
│   ├── services/                 api_client.dart (our backend), rates_service.dart (Frankfurter),
│   │                             notification_service.dart (push), session_store.dart (saved login)
│   ├── theme/ constants/ utils/  Colours, fonts, small helpers
├── assets/                       Logo, icons, images
├── android/ ios/ web/ ...        Platform folders created by Flutter
├── backend/                      <- The Node.js server (JavaScript)
│   ├── server.js                 Backend starts here
│   ├── routes/                   Which URL goes to which function
│   ├── controllers/              The actual logic (users, conversions, alerts, admin, news ...)
│   ├── middleware/               Login check and admin check
│   ├── jobs/rateWatcher.js       Runs every 30 min: alerts + daily update
│   ├── utils/                    notifier.js (push + inbox), mailer.js (email, not working)
│   ├── config/                   db.js (MySQL), firebaseAdmin.js, env.js
│   ├── scripts/                  setAdminRole.js, createDevAdmin.js ...
│   └── database/                 schema.sql + migrations/
├── Docs/                         <- This documentation
└── pubspec.yaml                  Flutter packages list
```

**Technologies**

| Layer | Technology |
|---|---|
| App | Flutter (Dart) |
| Login | Firebase Authentication (email/password + Google) |
| Push notifications | Firebase Cloud Messaging |
| Backend | Node.js + Express 5 |
| Database | MySQL (Clever Cloud) |
| Hosting | Render (backend) |
| Rates | Frankfurter API |
| News | Google News RSS |

---

## 9. Security in simple terms

| What | How we do it |
|---|---|
| Passwords | Only Firebase stores them. Never in MySQL |
| Who is calling? | Every protected request carries a Firebase token that the backend verifies |
| Users seeing each other's data | Every query is filtered by the logged-in user's own UID |
| Admin power | Comes from the Firebase `admin` badge, **not** from anything the app sends. A normal user cannot give themselves admin |
| Email codes | Saved scrambled (hashed), expire in 10 minutes, 5 wrong tries max |
| Secrets | `.env` and the Firebase key file are kept out of GitHub |
