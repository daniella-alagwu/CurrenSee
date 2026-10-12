# CurrenSee — User Instruction Manual

## 1. About CurrenSee

CurrenSee helps you view reference exchange rates, convert an amount between supported currencies, save conversions, follow short-term rate trends, create rate alerts and read currency-market news. The app is an information and calculation tool; it does not exchange money or process payments.

Rates are daily reference rates. They can differ from the rate offered by a bank, card issuer, bureau de change or transfer provider.

## 2. Create an account

1. Open CurrenSee and choose **Create An Account**.
2. Enter your email address and a password, then confirm the password.
3. Choose your country and preferred starting currency.
4. Submit the form. CurrenSee creates the sign-in account with Firebase Authentication and sends an email-verification link.
5. Check your inbox, including Spam/Junk. Open the link, then return to CurrenSee and choose **I've verified — continue**.

The country identifies your profile location. Your preferred currency is the starting currency for conversion; they are separate settings.

The verification screen also offers a six-digit email-code option. Use it only when the project’s email service is configured and available. The Firebase verification link is the recommended option for the deployed app.

## 3. Log in and reset a password

- On the welcome screen, choose **I already have an account**, enter your email and password, and tap **Log in**.
- If your email is not verified, follow the verification instructions shown in the app.
- To reset a forgotten password, choose **Forgot password?**, enter your account email and request a reset link. Check Spam/Junk as well as your inbox.

An authorised administrator may see an Admin home after signing in. Admins can choose **User mode** to use the normal app screens.

## 4. Convert currencies

1. Open **Home** or **Convert**.
2. Select the base currency (the amount you have) and target currency (the currency you want to compare it with).
3. Enter the amount. Use the swap control to reverse the pair.
4. Review the displayed rate and converted estimate.
5. Choose **Convert Now** to save the conversion to your history.

The saved history is associated with your CurrenSee profile. If the history is empty, make a conversion and save it first.

## 5. View rates and trends

Open **Rates** to view the available currencies and current reference-rate information. The home screen also shows a short trend for the selected pair. Pull down to refresh when available.

The conversion and trend screens currently list these 19 currency codes. The registration currency picker may display additional currencies; choose one from this list for full conversion and rate support:

**USD, EUR, GBP, JPY, CAD, AUD, INR, NGN, CHF, CNY, SGD, ZAR, MXN, BRL, NZD, SEK, NOK, HKD, KRW**

The Nigerian naira (NGN) is included. Israeli new shekel (ILS) is not currently in the conversion catalogue. A currency appearing in the registration picker does not necessarily mean it is available for conversion. Rate data must also be available from the provider.

## 6. Create and manage rate alerts

1. Open the **Alerts** option from the notifications area.
2. Choose a currency pair, enter a target rate, and choose whether the alert should trigger **above** or **below** that rate.
3. Save the alert. You can review or remove saved alerts from the alerts screen.

The backend checks alert conditions on a schedule. Reference rates are updated daily, so an alert may not trigger at the instant a market price moves through your target. Enable notification permissions if you want device push notifications; in-app notifications are also available.

## 7. Notifications, news and support

- Tap the notification bell to review in-app notifications and open rate alerts.
- Open **News** from the home screen’s news action. Tap an article to open its source outside CurrenSee.
- Open the side menu and choose **Contact** to send a support message. Replies are shown in the in-app conversation.

## 8. Profile and preferences

Open the side menu and choose **Profile settings** to review or change your profile information and preferences. Your country is profile information; your default base and target currencies are conversion preferences.

## 9. Frequently asked questions

### What is CurrenSee?

CurrenSee is a currency-reference and conversion app. It displays rates and estimates, saves conversion history, and provides rate alerts, notifications, news and support tools.

### What is an exchange rate?

An exchange rate tells you how much of a target currency corresponds to one unit of a base currency. For example, if 1 USD = 0.92 EUR, one US dollar is worth 0.92 euros at that reference rate.

### How often do rates change?

The app uses Frankfurter reference-rate data, which is updated daily. Rates are not a live tick-by-tick market feed. See [Frankfurter’s API information](https://frankfurter.dev/) for the provider’s current coverage and update details.

### Why might CurrenSee’s rate differ from my bank’s rate?

CurrenSee displays a reference rate. Banks, card providers and exchange services may use their own buy/sell rates, add a spread or charge fees. Their final transaction amount can therefore differ from the app’s estimate.

### Does CurrenSee charge a conversion fee?

CurrenSee calculates estimates; it does not perform or settle currency transactions, and the app does not charge a conversion fee. A bank, card provider or transfer service may charge its own fees if you make a transaction with it.

### Which currencies can I choose?

The app currently offers the 19 currencies listed above. NGN is included; ILS is not currently available in the app’s list. Availability of a quote can also depend on the rate provider.

### Why can’t I see a saved conversion?

A conversion appears in history after you use **Convert Now** to save it. You must be signed in, and the backend must be reachable when saving.

### I did not receive a verification link. What should I do?

Check that the address is correct, look in Spam/Junk, and use **Resend verification link** on the verification screen. If it still does not arrive, contact the project support team. The six-digit code option requires the backend’s SMTP service to be configured.

### The rates or backend will not load. What should I do?

Check your internet connection and try again. If the message says the CurrenSee backend is unreachable, the hosted service or app API address may need attention; contact the project team. Rate data also depends on the external rate provider being available.

### Can I change my password inside the app?

Use **Forgot password?** on the login screen to request a Firebase password-reset link. Follow the instructions in that email.

## 10. Safety and accuracy

CurrenSee is for reference and educational use. Confirm rates, fees and final amounts with the provider that will process your transaction before making financial decisions.
