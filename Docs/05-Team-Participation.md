# 05 - Team Participation

**Project:** CurrenSee - Currency Conversion App
**Client (from the brief):** ABC Finance Ltd.
**Group lead:** Alagwu Mmesoma Daniella

---

## 1. Who did what

| Member | Role | What they worked on |
|---|---|---|
| **Daniella** (Group lead) | Front end and user interface | Set up the shared GitHub repository and invited the team. Chose the colours and visual direction. Designed the brand logo. Built the splash screen and the user-facing pages. Connected the front end to the backend. Helped bring all screens together |
| **Tobi** | Backend and database | User accounts and authentication. Designed the MySQL data model. Built the Node.js / Express API and the Firebase-based verification. Added profile, preferences and conversion-history features |
| **Kaamil** | Rates and notifications | Exchange rates and historical rates. Rate alerts and notifications. Worked on the rates provider, rate trends, alert checking, and connecting these to the app and backend |
| **David** | Documentation and testing | Tracked project progress. Organised the documentation. Wrote down the development process and contributions. Coordinated testing |
| **Vishal** | Research and FAQ | Researched project information. Prepared supporting content for the documentation and user manual. Wrote the FAQs |
| **Emmanuel** | Presentation | Led presentation coordination. Organised how the features, objectives and process are presented. Prepared the group to demo CurrenSee |

---

## 2. Which part of the project belongs to whom (quick map, approximate)

This map is based on the roles above. Edit it if your real split was different.

| Part of the project | Main owner |
|---|---|
| `lib/` screens, theme, splash, logo | Daniella |
| `lib/services/api_client.dart` (front end <-> backend link) | Daniella |
| `backend/` login, users, profile, preferences, conversions | Tobi |
| `backend/database/` | Tobi |
| `lib/services/rates_service.dart`, `backend/jobs/rateWatcher.js`, `backend/utils/notifier.js` | Kaamil |
| `Docs/` | David (with help from the whole team) |
| FAQs and user guide content | Vishal |
| Presentation / demo video | Emmanuel |

---

## 3. How we worked together

1. **Read the brief** and listed the screens, data and services we needed.
2. **Shared repository.** Daniella created one GitHub repository and added everyone as collaborators.
3. **Split the work** by area (table above).
4. **Branches and merges.** Each person worked on their own branch, pushed to GitHub, and merged into the main branch when ready.
5. **Joined the pieces** (UI + backend + rates + notifications) and fixed integration problems together.
6. **Tested and documented** at the end.

---

## 4. Timeline of the project

| Stage | What happened |
|---|---|
| 1. Requirements | Read the brief, listed features, created the GitHub repository |
| 2. Look and feel | Chose green, gold and slate colours; designed the logo; started the Flutter screens and splash screen |
| 3. Login, API and database | Email/password login with Firebase. Node.js API and MySQL database. Added an SMTP email-code option (later stopped working, so Firebase's email link is used) |
| 4. Going online | The backend was first shared through a VS Code forwarded port from one laptop. We moved the backend to **Render** and the database to **Clever Cloud** |
| 5. Rates and notifications | Exchange rates, trends, alerts, notifications and news |
| 6. Joining everything | Fixed API addresses, login and profile navigation, and currency-preference problems |
| 7. Admin tools | Admin dashboard, user management (suspend / promote / delete), support inbox, announcements |
| 8. Documentation and testing | These documents, the user manual, testing and the demo |

---

## 5. Problems we hit and how we solved them

| Problem | What we did |
|---|---|
| The forwarded port only worked while one teammate's laptop was on | Moved the backend to Render and the database to Clever Cloud so everyone uses the same online services |
| Users appeared in Firebase but not in the MySQL database | Made the design clear: Firebase holds the login, MySQL holds the app data. The app now creates the MySQL profile after sign-in, and retries if it failed the first time |
| The first exchange-rate source did not cover the currencies we needed | Switched to the Frankfurter API. The app has its own list of 19 currencies (including NGN) |
| SMTP email codes stopped working | Use Firebase's verification link only |

---

## 6. Evidence of participation

Where a marker can look to confirm who did what:
- **GitHub commit history and pull requests** - shows each person's commits and dates.
- **This file** - the agreed split of responsibilities.
- **Status reports** your group sent to the eProject team during the project.
