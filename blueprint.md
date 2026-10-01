# CurrenSee — Project Blueprint

> Client: **ABC Finance Ltd.** · Platform: Flutter (iOS + Android) · Package: `currensee` · Dart SDK `^3.12.0`
> Living document. Update it in the same PR as any change to structure, scope or architecture, and log the change in `CHANGELOG.md`.

**Status legend:** ✅ Done · 🟡 In progress · ⬜ Planned · ❓ Decision needed

---

## 1. Product Summary

CurrenSee is a real-time foreign exchange and financial tracking mobile app. It gives users:

1. **Live currency conversion**
2. **Rate alerts**
3. **Historical trends**
4. **Financial news**

Brand posture: a secure, high-value financial tracker. Emerald + gold, clean slate surfaces, financial movement always shown in Mint/Red.

---

## 2. Current State (as of 2026-09-23)

| Area | Status | Notes |
| :--- | :--- | :--- |
| Brand lock (`BRAND.md`, `AppColors`) | ✅ | Single source of truth for colors. v1.1 extended palette proposed, pending client approval |
| Logos and generated assets | ✅ | Full light/dark logo, mark, native splash image, Android 12 splash |
| Launcher icons (iOS, Android adaptive, themed) | ✅ | Configured in `pubspec.yaml`; run `dart run flutter_launcher_icons` |
| Native splash | ✅ | White background + full light logo; run `dart run flutter_native_splash:create` |
| Animated splash screen | ✅ | 4.4s, light sweeps + breathing logo, tagline, "Commissioned by ABC Finance Ltd." footer |
| Theme (`AppTheme.light`) | ✅ | Material 3, seeded from `emeraldBg`, all colors via `AppColors` |
| Navigation shell | ⬜ | Placeholder "Home" screen after splash |
| Everything in section 4 | ⬜ | Not started |

---

## 3. Architecture

### 3.1 Layers (proposed)

```
UI (screens, widgets)
   ↓ reads state / calls actions
State management  (❓ see 6.1)
   ↓
Repositories  (CurrencyRepository, AlertsRepository, NewsRepository)
   ↓
Data sources  (Remote: rates API, news API, push · Local: cache, settings)
```

Rules:
- Widgets never call HTTP or storage directly. They go through state → repository.
- Repositories return app models, not raw JSON.
- Colors only from `AppColors`. No `Color(0xFF...)` in widget code (see `BRAND.md` §7).

### 3.2 Folder structure

```
lib/
├─ main.dart                     ✅ app entry, native splash hand-over
├─ constants/
│  ├─ colors.dart                ✅ AppColors (locked)
│  └─ assets.dart                ✅ AppAssets
├─ theme/
│  └─ app_theme.dart             ✅ ThemeData built from AppColors
├─ screens/
│  ├─ splash_screen.dart         ✅
│  ├─ onboarding/                ⬜
│  ├─ shell/                     ⬜ bottom-nav container
│  ├─ convert/                   ⬜
│  ├─ markets/                   ⬜ rates list + currency detail (trends)
│  ├─ alerts/                    ⬜
│  ├─ news/                      ⬜
│  └─ settings/                  ⬜
├─ widgets/                      ⬜ shared components (rate tile, change chip, currency picker)
├─ models/                       ⬜ Currency, Rate, RatePoint, Alert, NewsItem
├─ repositories/                 ⬜
├─ services/                     ⬜ api client, notifications, local storage
└─ utils/                        ⬜ formatters (money, percent, date)

assets/
├─ brand/                        ✅ logos, splash images
└─ icons/                        ✅ launcher icon sources
```

---

## 4. App Structure and Features

### 4.1 Navigation map

```
Splash ─▶ (first launch) Onboarding ─▶ Shell
      └─▶ (returning)                  Shell
Shell (bottom navigation)
 ├─ Convert   ─ Currency picker (modal)
 ├─ Markets   ─ Currency detail ─ Historical chart
 ├─ Alerts    ─ Create / edit alert
 ├─ News      ─ Article view
 └─ Settings
```

### 4.2 Screens

| Screen | Purpose | Key contents | Status |
| :--- | :--- | :--- | :--- |
| **Splash** | Brand moment, hand-over from native splash | Full light logo, tagline, "Commissioned by ABC Finance Ltd." | ✅ |
| **Onboarding** | Explain value, set base currency | 2–3 pages, "Get Started" (Warm Gold CTA) | ⬜ |
| **Convert** | Core feature: live conversion | Amount input, from/to pickers, swap button, live result, last-updated time | ⬜ |
| **Markets** | Live rates overview | Base-currency selector, search, list of rate tiles with change chips, favorites | ⬜ |
| **Currency detail** | Historical trends | Line chart, range tabs (1D/1W/1M/1Y), high/low/change, "Set alert" | ⬜ |
| **Alerts** | Rate alerts | Active alerts list, create/edit (pair, target rate, above/below), enable toggle | ⬜ |
| **News** | Financial news | Feed, filter by currency/topic, article view | ⬜ |
| **Settings** | Preferences | Base currency, theme, notification settings, about (ABC Finance Ltd., version) | ⬜ |

### 4.3 Feature detail

**Live conversion**
- Amount and pair inputs update the result as the user types (debounced).
- Swap pair, recent pairs, favorites.
- Shows rate timestamp; if data is stale or offline, show a **Warning Amber** badge and the last cached rate.

**Rate alerts**
- Alert = currency pair + target rate + direction (above/below) + on/off.
- Delivered as push notifications; checked server-side (a device cannot poll reliably in background).
- Active-alert badge uses **Positive Mint**.

**Historical trends**
- Per-pair series for 1D / 1W / 1M / 1Y (ranges finalized once the data provider is chosen).
- Chart line and change chips follow financial-indicator colors (Mint up / Red down).

**Financial news**
- Headline feed with source and time, tap to read (in-app web view or external, ❓ see 6).
- Currency-tagged filtering where the provider supports it.

---

## 5. Design System Application

Full spec in `BRAND.md`. Where each color family is used in this app:

| Element | Color |
| :--- | :--- |
| App bars, feature headers, onboarding | Deep Emerald |
| Active tab indicator, focus borders, tagline | Forest Green |
| Primary CTAs ("Get Started", "Convert") | Warm Gold, text in Text Dark Slate |
| Card borders, subtitles | Metallic Gold |
| Screen background | Surface Slate; cards and modals Pure White |
| Positive/negative rate change | Positive Mint / Negative Red (and Mint/Red tint chips) |
| Stale or offline data | Warning Amber (proposed v1.1) |
| Splash | `AppColors.splashLight` gradient, white to Surface Slate |

Assets: `assets/brand/*` (logos) and `assets/icons/*` (launcher). The light logo goes only on light surfaces; the dark logo only on emerald.

---

## 6. Open Decisions ❓

None of these are decided yet. Record the outcome here and in `CHANGELOG.md` when resolved.

| # | Decision | Options / notes |
| :-- | :--- | :--- |
| 6.1 | State management | e.g. Riverpod, Bloc, Provider |
| 6.2 | Exchange-rate data provider | Needs: live rates, historical series, coverage of the currencies ABC Finance cares about, licensing suitable for a commercial app |
| 6.3 | News provider | Third-party API vs. ABC Finance's own feed |
| 6.4 | Backend | Needed for alert checking + push. Own backend vs. BaaS (e.g. Firebase). Ties to 6.2 rate limits and API-key security (keys must not ship in the app) |
| 6.5 | User accounts | Are alerts/favorites tied to a login, or device-local? Determines auth scope |
| 6.6 | Local storage and caching | e.g. shared_preferences, Hive, Isar, SQLite |
| 6.7 | Charting library | e.g. fl_chart or a custom painter |
| 6.8 | Dark mode | Palette has `emeraldDeep` and `emeraldGlow` ready; needs a client decision |
| 6.9 | Navigation package | Navigator 2 vs. go_router |
| 6.10 | Supported regions and languages | Currency formatting, localization |
| 6.11 | v1.1 extended palette | Client approval of `BRAND.md` §5 |
| 6.12 | Vector master of the logo | Current source is 500px raster; store submission needs SVG or high-res |

---

## 7. Roadmap (proposed)

| Phase | Scope | Status |
| :--- | :--- | :--- |
| **0. Foundation** | Brand lock, assets, theme, launcher icon, splash | ✅ |
| **1. Skeleton** | Decide 6.1, 6.9; navigation shell, onboarding, shared widgets | ⬜ |
| **2. Convert + Markets** | Decide 6.2, 6.6; repository layer, live conversion, rates list, caching and offline state | ⬜ |
| **3. Trends** | Decide 6.7; currency detail, historical charts | ⬜ |
| **4. Alerts** | Decide 6.4, 6.5; alert CRUD, push notifications | ⬜ |
| **5. News** | Decide 6.3; feed and article view | ⬜ |
| **6. Polish and release** | Settings, error/empty states, accessibility, performance, store assets, QA | ⬜ |

---

## 8. Team Conventions

1. **Colors:** `BRAND.md` first, then `colors.dart`, then use it. No exceptions.
2. **Changelog:** every merged change adds a line to `CHANGELOG.md` under `[Unreleased]`.
3. **Blueprint:** structure/scope/decision changes update this file in the same PR.
4. **Assets:** new assets go under `assets/brand/` or `assets/icons/` and are referenced through `AppAssets`, never by string path in widgets.
5. **Config hex exceptions:** only the `flutter_launcher_icons` and `flutter_native_splash` blocks in `pubspec.yaml` may contain raw hex (they cannot import Dart).
6. **Tests:** new logic ships with tests; `flutter analyze` and `flutter test` must pass before merge.

---

## 9. Setup for New Contributors

```
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter run
```

Requires Flutter with Dart `^3.12.0` (the splash uses `Color.withValues`, Flutter 3.27+).