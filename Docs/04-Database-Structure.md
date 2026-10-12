# 04 - Database Structure (MySQL on Clever Cloud)

> **In one line:** CurrenSee keeps its data in a **MySQL** database hosted on **Clever Cloud**. The backend (on Render) is the only thing that talks to it.

**Related files:** the ready-to-run SQL is in [`database/currensee_full_schema.sql`](database/currensee_full_schema.sql). Login details for the database are in [06-Login-Credentials.md](06-Login-Credentials.md).

---

## 1. Why we have two places that store users

This confuses a lot of people, so read this first.

| Where | What it stores | Why |
|---|---|---|
| **Firebase Authentication** | Email, **password**, "is the email verified?", Google sign-in, the `admin` badge | Firebase is built to handle passwords safely, so we did not write our own |
| **MySQL (Clever Cloud)** | Everything else: name, country, preferred currency, conversion history, alerts, notifications, support chat | This is our own app data |

**The link between them is `users.firebase_uid`.** Every user has one Firebase ID (the "UID"). We save that same ID in the `users` table. When the app calls the backend, the backend reads the UID from the login token and finds the matching row.

> Passwords are **never** saved in MySQL.

---

## 2. The big picture (which table belongs to what)

```
                          currencies  (list of currency codes: USD, EUR, NGN ...)
                              ^
                              | (used by 5 tables below)
                              |
 users --+-- user_preferences      default base + target currency, notification switches
         |
         +-- conversion_history    every conversion the user saved
         +-- rate_alerts           "tell me when USD/NGN goes above 1600"
         +-- notifications         the in-app inbox (bell icon)
         +-- device_tokens         phones that should get push notifications
         +-- support_messages      the chat between a user and the admin
         +-- support_tickets  *    (created, not used yet)
         +-- feedback         *    (created, not used yet)

 email_otp_codes   six-digit email codes (linked to a Firebase UID)
 news_articles     cached news headlines (shared by everyone)
 exchange_rates *  (created, not used yet)
 faqs           *  (created, not used yet)

 * = table exists in the database but the app does not read or write it yet
```

`users` is the "parent" table. If a user is deleted, their preferences, history, alerts, notifications, devices and messages are **deleted automatically** (`ON DELETE CASCADE`).

**Totals:** 14 tables. 10 are used by the app. 4 are prepared for future features (see section 5).

---

## 3. Every table, in plain words

### 3.1 `users` - one row per person

| Column | Type | What it means |
|---|---|---|
| `id` | INT, auto | Our own user number. **Primary key.** Other tables point to this |
| `firebase_uid` | VARCHAR(255), unique | The Firebase ID. This is the link to Firebase |
| `email` | VARCHAR(255), unique | Email address |
| `auth_provider` | VARCHAR(30) | How they sign in: `password` or `google.com` |
| `name` | VARCHAR(100) | Display name |
| `country_code` / `country_name` | CHAR(2) / VARCHAR(100) | e.g. `NG` / `Nigeria` |
| `role` | `USER` or `ADMIN` | What the person is allowed to do |
| `status` | `ACTIVE` or `SUSPENDED` | A suspended user can only use the support chat to appeal |
| `avatar` | MEDIUMTEXT | Profile picture saved as text (base64) |
| `photo_url` | VARCHAR(1024) | Profile picture link (comes from Google sign-in) |
| `is_primary_admin` | BOOLEAN | `TRUE` for the one "owner" admin |
| `primary_admin_slot` | auto-generated | Trick to make sure there can only be **one** primary admin (see below) |
| `created_at` | TIMESTAMP | When the row was created |

**The "only one primary admin" trick:** `primary_admin_slot` is calculated by MySQL: it is `1` when `is_primary_admin` is true and `NULL` otherwise. It has a `UNIQUE` rule, and MySQL allows many `NULL`s but only one `1`. So a second primary admin is impossible.

### 3.2 `user_preferences` - one row per user (settings)

| Column | What it means |
|---|---|
| `user_id` | Which user (primary key **and** link to `users.id`) |
| `default_base_currency` | The "from" currency the user starts with (default `USD`) |
| `default_target_currency` | The "to" currency (default `EUR`) |
| `push_enabled` | Phone push notifications on/off |
| `alert_notifications_enabled` | Rate-alert notifications on/off |
| `last_digest_date` | The last day we sent the "daily rate update", so we do not send it twice |

### 3.3 `currencies` - the list of currencies

| Column | What it means |
|---|---|
| `code` | 3 letters, e.g. `NGN`. **Primary key** |
| `name` | e.g. `Nigerian Naira` |
| `symbol` | e.g. `₦` |
| `is_active` | `FALSE` hides the currency |

The schema file pre-loads **19 currencies**: USD, EUR, GBP, JPY, CAD, AUD, INR, NGN, CHF, CNY, SGD, ZAR, MXN, BRL, NZD, SEK, NOK, HKD, KRW.

### 3.4 `conversion_history` - saved conversions

| Column | What it means |
|---|---|
| `id` | Unique number (BIGINT) |
| `user_id` | Who made it (link to `users.id`) |
| `from_code`, `to_code` | The two currencies (link to `currencies.code`) |
| `amount` | How much they converted, e.g. `25.0000` |
| `rate_used` | The rate at that moment, e.g. `0.92000000` |
| `result` | `amount x rate_used`, **calculated by the backend** (not trusted from the phone) |
| `created_at` | When it was saved |

### 3.5 `rate_alerts` - "notify me when..."

| Column | What it means |
|---|---|
| `user_id` | Owner of the alert |
| `base_code`, `target_code` | The currency pair |
| `threshold` | The target rate |
| `direction` | `ABOVE` or `BELOW` |
| `is_active` | `TRUE` until the alert fires once, then it switches to `FALSE` |
| `triggered_at` | When it fired |

A user can have up to **20 active alerts**.

### 3.6 `notifications` - the in-app inbox

| Column | What it means |
|---|---|
| `user_id` | Who receives it |
| `title`, `body` | The message |
| `type` | `ALERT` (from a rate alert or daily update) or `SYSTEM` (admin announcement) |
| `is_read` | Has the user opened it? |

### 3.7 `device_tokens` - phones for push notifications

| Column | What it means |
|---|---|
| `user_id` | Whose phone |
| `fcm_token` | The address Firebase uses to reach that phone (unique) |
| `platform` | `android` or `ios` |

### 3.8 `support_messages` - user <-> admin chat

| Column | What it means |
|---|---|
| `user_id` | The user the conversation belongs to (one thread per user) |
| `sender` | `USER` or `ADMIN` |
| `body` | The message (max 1000 characters) |
| `tag` | Optional label. A suspension appeal is saved with a tag so the admin can spot it |
| `is_read` | Read or not |

### 3.9 `email_otp_codes` - six-digit email codes

| Column | What it means |
|---|---|
| `firebase_uid` | Whose code (unique: one code at a time) |
| `code_hash` | The code **scrambled** (SHA-256). We never save the real code |
| `expires_at` | Valid for 10 minutes |
| `attempts` | Wrong guesses so far (5 max) |

> This is an optional extra way to verify an email. It needs SMTP email sending, which is **not working any more** in our hosted setup, so the app uses Firebase's verification link instead.

### 3.10 `news_articles` - cached headlines

| Column | What it means |
|---|---|
| `title`, `summary`, `url`, `source` | The article |
| `published_at` | Date from the news feed |

The backend downloads the news feed, saves new articles here, and serves them to the app. If the feed is down, the app still shows the saved ones.

---

## 4. Table relationships (for your viva / presentation)

| Parent table | Child table | Link | If the parent is deleted |
|---|---|---|---|
| `users.id` | `user_preferences.user_id` | one-to-one | child deleted |
| `users.id` | `conversion_history.user_id` | one-to-many | child deleted |
| `users.id` | `rate_alerts.user_id` | one-to-many | child deleted |
| `users.id` | `notifications.user_id` | one-to-many | child deleted |
| `users.id` | `device_tokens.user_id` | one-to-many | child deleted |
| `users.id` | `support_messages.user_id` | one-to-many | child deleted |
| `currencies.code` | `user_preferences` (2 columns), `conversion_history` (2), `rate_alerts` (2), `exchange_rates` (2) | one-to-many | **blocked** (cannot delete a currency that is in use) |

---

## 5. Tables that exist but are not used yet

We created these while planning. The app does not read or write them yet, so they stay empty. Say this honestly if asked.

| Table | Planned for | What we use instead today |
|---|---|---|
| `exchange_rates` | Storing daily rates ourselves | The app gets rates live from the Frankfurter API |
| `faqs` | Loading FAQs from the database | FAQs are written in the [User Manual](09-User-Manual.md); the app has an in-app User guide screen |
| `support_tickets` | Formal support tickets | The `support_messages` chat |
| `feedback` | Feedback and bug reports | The `support_messages` chat (Contact screen) |

---

## 6. Hosting on Clever Cloud

| Item | Value |
|---|---|
| Database type | MySQL add-on on Clever Cloud |
| Database name | `bsj6vi7c3gpqyz9nujvw` |
| Host, user, password, port | In [06-Login-Credentials.md](06-Login-Credentials.md) |
| Who connects | The backend on Render, using the `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` settings |

**How to see the database:** In the Clever Cloud dashboard open your MySQL add-on. It shows the connection details and links to a web tool (Adminer / phpMyAdmin) where you can browse tables. You can also use MySQL Workbench with the same details.

**Small plans allow only a few connections at once.** Our backend opens up to 10 (`connectionLimit: 10` in `backend/config/db.js`). If you ever see a "too many connections" error, lower that number.

---

## 7. How to build the database from zero

1. Create an empty MySQL database (on Clever Cloud this is already done for you).
2. Open it in Adminer / phpMyAdmin / MySQL Workbench.
3. Run all of [`database/currensee_full_schema.sql`](database/currensee_full_schema.sql) **once**.
4. You will get 14 tables and 19 currencies.

> **Do not run the files in `backend/database/migrations/` on top of this.** Those files are only for older databases. The full schema already includes everything, and running them again causes "column already exists" errors.

**Note about `backend/database/schema.sql`:** that older file starts with `USE bsj6vi7c3gpqyz9nujvw;` and is missing three columns that were added later by migrations (`users.auth_provider`, `users.photo_url`, `support_messages.tag`). Use `currensee_full_schema.sql` instead.

---

## 8. How to make a database backup

The final submission needs a **database backup**. The schema file gives the structure; a backup also contains the real data.

**Option A - Clever Cloud / Adminer (easiest):** open Adminer from the Clever Cloud dashboard -> choose the database -> **Export** -> output "save" -> format "SQL" -> tick tables + data -> Export. Save the file as `currensee_backup.sql`.

**Option B - command line** (needs MySQL client tools installed):

```
mysqldump -h <DB_HOST> -P <DB_PORT> -u <DB_USER> -p <DB_NAME> > currensee_backup.sql
```

It will ask for the password. Put `currensee_backup.sql` in the submission ZIP.

