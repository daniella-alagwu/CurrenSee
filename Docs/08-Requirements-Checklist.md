# 08 - Requirements Checklist

This page matches **every requirement in the eProject brief** to what we built. Legend: **Done** = works in the app. **Partly** = works, with a limit we explain. 

## Functional requirements

| # | Requirement from the brief | Status | How CurrenSee does it |
|---|---|---|---|
| 1 | **Register and log in securely**, email/password and social login | Done | Firebase Authentication: email + password with email-verification link, **Google sign-in**, and "Forgot password?" reset email |
| 2 | **Currency conversion** with a base and target currency, real-time rates, amount in, result out | Done | Convert tab and Home quick-convert. Rates from the Frankfurter API. *Rates are daily reference rates, not second-by-second prices* |
| 3 | **Currency list**, searchable and filterable, with symbols and names | Partly | The app shows 19 currencies with flag, code, name and symbol on the Rates screen and in the pickers. **There is no search box** in that list |
| 4 | **Exchange rate information**, with historical trends | Partly | Rates screen shows the latest rates. Tapping a currency shows a **7-day trend** line. Longer history is not shown |
| 5 | **Conversion history** with date, rates, amounts | Done | Saved when the user taps **Convert Now**. Shown in Home -> Saved Pairs. Stored in the `conversion_history` table |
| 6 | **Rate alerts** for currency pairs, with notification when reached | Done | Create alerts (above / below a rate). The backend checks every 30 minutes and sends an in-app notification and a push |
| 7 | **User preferences** (default base currency, remembered settings) | Done | Profile settings: default base and target currency, push switch, alert switch. Stored in `user_preferences` |
| 8 | **Currency news and market trends** | Done | News screen (Google News feed). Trend lines on Home and Rates |
| 9 | **Support and help centre**, FAQs and guides, contact support | Done | In-app **User guide** screen, **Contact** chat with the admin, FAQs in the [User Manual](09-User-Manual.md) |
| 10 | **Notifications**, push for alerts and updates, manage preferences | Done | Bell-icon inbox, push through Firebase Cloud Messaging, admin announcements, on/off switches in Profile settings. *Push needs notification permission on the phone* |
| 11 | **User feedback**, give feedback and report issues | Partly | Users send feedback and report problems through the **Contact** chat, and admins reply. There is no separate "feedback form". (A `feedback` table exists in the database but is not used yet) |

## Non-functional requirements

| Requirement | Status | Evidence |
|---|---|---|
| Responds in 1-2 seconds | Done, with one exception | Normal actions are quick. The **first** request after the free-tier server has been idle can take about a minute to wake up |
| Fast loading | Done | Native white splash, then an animated splash while the app starts |
| Intuitive interface | Done | Bottom tabs (Home, Rates, Convert, Settings), simple screens, consistent colours (green, gold, slate) |
| Accessible, clear fonts and navigation | Done (not formally audited) | Clear labels and readable text, consistent colour palette (see `BRAND.md`) |
| Operability | Done | Hosted backend and database, a health-check address, request logs |
| Error handling | Done | Friendly messages for no internet, wrong password, unverified email, backend down, rates unavailable, suspended account. The backend always replies with an error `code` and `message` |
| Scalability | Done (at project scale) | Backend and database are separate hosted services. The database uses a connection pool and paging (`limit` / `offset`) for lists |
| Security | Done | Firebase login on every protected route, per-user data access, admin rights from a Firebase badge that users cannot give themselves, secrets kept out of GitHub |
| User documentation | Done | [09-User-Manual.md](09-User-Manual.md) and the in-app User guide |
| Developer documentation | Done | This `Docs` folder |
| Video of the complete app working | Team to provide | Record it and include it in the submission (see [10-Submission-Checklist.md](10-Submission-Checklist.md)) |

## Extras we added beyond the brief

- **Admin dashboard** with statistics, user search, suspend / unsuspend / promote / demote / delete, and a support inbox.
- **Account suspension with appeals.**
- **Admin announcements** sent to all users.
- **Daily rate update** notification for each user's default pair.
- **Profile picture** upload.
- **Primary (owner) admin** protection: only one, and it cannot be removed from the app.

## Known limitations (we prefer to say these ourselves)

| Limitation | Why / what to know |
|---|---|
| Only 19 currencies | The list is fixed in the app (`RatesService`) and in the `currencies` table. Adding one means updating both |
| Rates are daily reference rates | The Frankfurter service publishes once per working day. A bank's rate can differ |
| No search box in the currency list | Not built yet |
| Six-digit email code not working | It needs an SMTP email service we no longer have. Firebase's verification link is the working method |
| **Transaction limits** screen shows sample numbers | It is a demonstration screen with fixed figures, not connected to real data |
| 4 database tables unused | `exchange_rates`, `faqs`, `support_tickets`, `feedback` (see [04-Database-Structure.md](04-Database-Structure.md)) |
| CurrenSee does not move money | It is an information and calculation tool only |
