# CurrenSee - Project Documentation

**A currency conversion app** built for ABC Finance Ltd. as an Aptech eProject.

|                   |                                                               |
| ----------------- | ------------------------------------------------------------- |
| **Batch / Group** | 061/058 - ADSE                                            |
| **Group lead**    | Daniella                                                      |
| **Team**          | Alagwu Daniella, Osinoiki Tobi, Otufowora Kaamil, Olawore David, Sanjay Vishal, Akonye Emmanuel               |
| **Live backend**  | https://currensee-f0sf.onrender.com (health check: `/health`) |

---

## What is CurrenSee?

CurrenSee, a multi platform application lets people **convert money between currencies**, see **rates and trends**, **save their conversion history**, set **rate alerts**, read **currency news**, and **chat with support**. Admins can manage users and reply to support messages.

It does not move any money. It is a calculation and information tool.

## How it is built (in 5 lines)

1. **App:** Flutter (Dart).
2. **Login:** Firebase Authentication (email/password and Google).
3. **Backend:** Node.js + Express, hosted on **Render**.
4. **Database:** MySQL, hosted on **Clever Cloud**.
5. **Rates and news:** Frankfurter API and Google News.

---

## Read the documents in this order

| File                                                                     | What you will find                                                     | Read it if you want to...                     |
| ------------------------------------------------------------------------ | ---------------------------------------------------------------------- | --------------------------------------------- |
| [01-API-List.md](01-API-List.md)                                         | Every outside API we use, and every backend route                      | Know what services and endpoints the app uses |
| [02-Backend-Hosting-Render.md](02-Backend-Hosting-Render.md)             | How the backend was put online on Render                               | Redeploy or understand hosting                |
| [03-App-Flow-and-Structure.md](03-App-Flow-and-Structure.md)             | Screens, user journey, data flows, folder map                          | Understand how the app works                  |
| [04-Database-Structure.md](04-Database-Structure.md)                     | All 14 tables, columns, relationships, Clever Cloud, backup            | Understand or rebuild the database            |
| [05-Team-Participation.md](05-Team-Participation.md)                     | Who did what, timeline, problems solved                                | See each member's contribution                |
| [06-Login-Credentials.md](06-Login-Credentials.md)                       | Admin, test user and database logins                                   | **Log in and test**                           |
| [07-How-To-Run-and-Test.md](07-How-To-Run-and-Test.md)                   | Run the app, 5-minute test script, local setup                         | Run or test the project                       |
| [08-Requirements-Checklist.md](08-Requirements-Checklist.md)             | Every requirement in the brief matched to our work, plus honest limits | Check we met the brief                        |
| [09-User-Manual.md](09-User-Manual.md)                                   | Guide and FAQs for app users                                           | Learn to use the app                          |
| [10-Submission-Checklist.md](10-Submission-Checklist.md)                 | What goes in the final ZIP                                             | Submit correctly (team use)                   |
| [database/currensee_full_schema.sql](database/currensee_full_schema.sql) | SQL that builds the whole database                                     | Create the database from zero                 |

## If you only have 5 minutes (markers)

1. Read [06-Login-Credentials.md](06-Login-Credentials.md).
2. Open `https://currensee-f0sf.onrender.com/health` and wait for `{"status":"ok"...}`.
3. Follow the **5-minute test script** in [07-How-To-Run-and-Test.md](07-How-To-Run-and-Test.md).
4. Look at [08-Requirements-Checklist.md](08-Requirements-Checklist.md) to see how each requirement was met.

## Words used in these documents

| Word                     | Meaning                                                                              |
| ------------------------ | ------------------------------------------------------------------------------------ |
| **API**                  | A way for one program to ask another for something                                   |
| **Endpoint / route**     | One address of an API, like `/api/users/me`                                          |
| **Backend**              | The server program that stores and serves our data                                   |
| **Token**                | A temporary ID card Firebase gives the app after login                               |
| **UID**                  | A user's unique Firebase ID                                                          |
| **Hosting**              | Running a program on someone else's always-on computer, so it is online all the time |
| **Environment variable** | A secret setting (like a password) stored on the host, not in the code               |
| **Push notification**    | A message that appears on the phone even when the app is closed                      |
| **Admin**                | A user with extra powers (manage users, answer support)                              |
