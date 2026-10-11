**Project overview**

CurrenSee is a currency-conversion and financial-tracking application developed for the eProject brief supplied by Aptech. The brief demanded features such as secure user accounts, currency conversion, exchange-rate and historical information, conversion history, rate alerts, preferences, market news, support, notifications, and user feedback.

The group used Flutter for the application, Firebase Authentication for account credentials and email verification, a Node.js/Express API for protected application operations, and MySQL for application data.




**Team organization**

The group first reviewed the project brief, identified its requirements, and divided responsibilities. The group lead, Daniella set up the shared GitHub repository, invited the other members as collaborators, and led the group’s user-interface work. The team used branches and GitHub pushes/merges to combine work.

The following are the responsibilities that were allocated to each member

Daniella (Group lead) — Front end and user interface:
Set up the shared repository; selected the initial visual direction and colours; developed the splash screen and user-facing pages; helped bring the screens together. Connected backend and frontend logic together. Designed brand logo.

Tobi — Backend and Database:
User accounts, authentication, API and backend logic. Designed the MySQL data model; implemented the Node.js/Express API and Firebase-backed verification flow; added profile, preference and conversion-history operations.

Kaamil — Rates and notifications:
Exchange rates, historical rates, rate alerts, notifications and integration.
Worked on the rates provider, rate trends, alert checking and notification features, and connecting those services to the app and backend.

Vishal — Documentation and testing:
Documentation and testing coordination.
Was assigned to track progress, create project documentation and coordinate testing.

Emmanuel — Research and presentation:
Research, content and presentation leadership. Researched and prepared project content and coordinated the project presentation.






**Development process**

1. Requirements and shared repository

The group started by reading the school brief and identifying the main screens, data and services the project would need. A shared GitHub repository gave all members a common base for development and integration.

2. Colors and logo
Daniella (Group lead) established the visual direction and began the Flutter interface, including the splash screen, logo and page layouts. The team used the green, gold and slate palette throughout the app and the logo was inspired by th app's purpose in dealing with currency, using the dollar sign.

3. Authentication, API and database
Tobi implemented email/password authentication using Firebase Authentication and initially with an SMTP alternative for users. Firebase keeps the authentication identity, password credential and verification state. The application’s MySQL database stores the separate CurrenSee profile and application data. Passwords are not stored in the MySQL user table.
The initial development setup used a VS Code forwarded port on Tobi’s computer. This was useful during local development, but it depended on that computer and tunnel being available. The API was later deployed to Render, and the MySQL database was moved to Clever Cloud so the API could use a shared hosted database. SMTP is no longer functional. Only firebase

4. Currency data and notifications
The rate service was changed to use the Frankfurter exchange-rate API. The Flutter app requests rates and short historical trends; the backend also checks saved rate alerts against reference-rate data. The application contains its own currency catalogue, including Nigerian naira (NGN). It does not currently expose every currency available from an external provider; for example, Israeli new shekel (ILS) is not in the current application catalogue.
The backend checks alert thresholds on a scheduled interval and creates in-app notifications. Firebase Cloud Messaging is used for device push notifications when the device and deployment are configured for it.

5. Integration and refinement
As the UI, backend, rates and notification work came together, the team addressed integration issues including changing API addresses, unstable local port forwarding, login/profile navigation and currency-preference consistency. The app’s API client now sends Firebase ID tokens to the protected backend routes, and account setup stores the profile and selected default currency in MySQL.



**Main challenges and decisions**

 A VS Code forwarded port depended on one developer’s computer staying available to access the same backend — The backend API was moved to Render and the database to Clever Cloud, so teammates and reviewers can use shared hosted services. 

Users appeared in Firebase but not in SQL after account creation — The architecture was clarified: Firebase Authentication stores login credentials and verification state; the backend creates the app profile and related data in MySQL after sign-in/verification. 

The original exchange-rate source did not meet the team’s currency-coverage needs — The rate service moved to Frankfurter. NGN is included in the app’s current currency list but the app list still needs coordinated updates when adding more currencies. 
