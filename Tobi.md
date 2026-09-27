# CurrenSee Authentication and Backend Summary

## What is implemented

- Flutter registration using email and password through Firebase Authentication.
- Registration also collects a country and preferred currency.
- Flutter login using Firebase Authentication.
- Email verification by Firebase verification link.
- Optional six-digit verification code sent by the Node.js backend using Nodemailer.
- MySQL profile and default preference storage.
- Firebase ID-token checks on protected backend endpoints.
- Placeholder home screen with the signed-in email and log-out button.

## Registration flow

1. User enters email, password, country, and preferred currency.
2. Firebase creates the account and sends a verification link.
3. The app attempts to save the profile in MySQL.
4. The user verifies by link or requests and enters the six-digit email code.
5. After verification, the app retries profile storage if needed and opens the placeholder home screen.

Firebase stores credentials and verification status. MySQL stores the app profile. A Firebase account can exist even if saving its MySQL profile failed.

## Backend endpoints

- `POST /api/users/create` — saves the Firebase user profile and preferences.
- `POST /api/users/otp/send` — sends a six-digit code.
- `POST /api/users/otp/verify` — verifies the code and updates Firebase verification status.

All three endpoints require a Firebase ID token.

## Current limitations

The currency dashboard and APIs for exchange rates, conversions, alerts, news, support, and feedback are not implemented yet. Some related database tables exist, but the backend does not use them yet.

## Email sender notes

OTP email displays **CurrenSee** and uses the address configured by `SMTP_USER`. Firebase sends verification links separately. Configure Firebase’s Authentication email template for link branding. A branded sending domain needs provider/Firebase setup and DNS records. Check Spam/Junk and the email provider’s delivery logs during testing.