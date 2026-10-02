# BRAND.md

# CurrenSee — Brand & Design System Guidelines (v1.1, locked)

> ⚠️ **STRICT GOVERNANCE WARNING**
> **This document is the Single Source of Truth for all color usage across the CurrenSee application.**
> NO new colors, hex codes, or inline color definitions may be introduced into the codebase without updating this document FIRST. All colors used in Flutter widgets MUST be mapped directly to constants inside `lib/constants/colors.dart`.

*Client: ABC Finance Ltd. · Palette verified against `FullLogo.png` and `HalfLogo.png` (sampled: logo green ≈ `#008058`–`#00B068`, logo gold ≈ `#D09000`–`#F8D048`).*

---

## 1. Core Brand Colors

| Color Name | Hex Code | Flutter Constant | Usage / Purpose |
| :--- | :--- | :--- | :--- |
| **Deep Emerald** | `#064E3B` | `AppColors.emeraldBg` | Primary app background (splash, dark app bar, feature headers), theme seed color, Android adaptive icon background. |
| **Forest Green** | `#008459` | `AppColors.forestGreen` | Secondary brand color, gradient stops, active tab indicators, primary action borders. Matches the "Curren" wordmark green. |

## 2. Accent & Highlight Colors

| Color Name | Hex Code | Flutter Constant | Usage / Purpose |
| :--- | :--- | :--- | :--- |
| **Warm Gold** | `#E1A72B` | `AppColors.goldWarm` | Primary CTA buttons ("Get Started", "Convert"), active icons, the "See" wordmark. Use **Text Dark Slate** for text on top. |
| **Metallic Gold** | `#D4AF37` | `AppColors.goldPrimary` | Subtitle text, card borders, badge outlines, metallic gradient overlays. |
| **Light Gold** | `#FFE57F` | `AppColors.goldLight` | Shimmer effects, glow highlights, subtle details on dark backgrounds. |

## 3. Neutral & Surface Colors (Light Mode)

| Color Name | Hex Code | Flutter Constant | Usage / Purpose |
| :--- | :--- | :--- | :--- |
| **Pure White** | `#FFFFFF` | `AppColors.white` | Text on dark green, active conversion cards and modals, "Curren" wordmark on emerald. |
| **Surface Slate** | `#F8FAFC` | `AppColors.surfaceSlate` | Default background for content-heavy pages. |
| **Text Dark Slate** | `#0F172A` | `AppColors.textDark` | Primary body text, currency values, labels on light surfaces. |
| **Text Muted Slate** | `#64748B` | `AppColors.textMuted` | Captions, timestamps, inactive inputs, helper text. |

## 4. Financial Indicator Colors

Reserved strictly for market movement, trends, and rate alerts.

| Color Name | Hex Code | Flutter Constant | Usage / Purpose |
| :--- | :--- | :--- | :--- |
| **Positive Mint** | `#10B981` | `AppColors.positiveMint` | Positive changes, upward arrows, profit %, active alert badges. |
| **Negative Red** | `#EF4444` | `AppColors.negativeRed` | Negative changes, downward arrows, loss %, error alerts. |

---

## 5. Extended Palette (v1.1 — proposed additions, derived from the logos)

Added because the locked palette has no answer for depth, dark mode, dividers, or state colors. Each is derived from the logo or is a neutral tint of an existing color. **Approve or strike before feature work begins.**

| Color Name | Hex Code | Flutter Constant | Why it exists / Usage |
| :--- | :--- | :--- | :--- |
| **Emerald Deep** | `#022C22` | `AppColors.emeraldDeep` | Darkest brand tone: dark-mode background, status bar, gradient floor. |
| **Emerald Glow** | `#0B6B52` | `AppColors.emeraldGlow` | Lit center of the app-icon/splash radial gradient; cards sitting on emerald backgrounds. |
| **Logo Green** | `#00A860` | `AppColors.logoGreen` | Bright green of the logo arrow; illustrations and highlights on dark surfaces (Forest Green is too dim there). |
| **Gold Deep** | `#D09000` | `AppColors.goldDeep` | Shadow end of the coin's gold gradient; pressed state of Warm Gold buttons. |
| **Border Slate** | `#E2E8F0` | `AppColors.borderSlate` | Dividers, input borders, card outlines on Surface Slate. |
| **Mint Tint** | `#D1FAE5` | `AppColors.mintTint` | Background chips for positive changes (text stays Positive Mint/Emerald). |
| **Red Tint** | `#FEE2E2` | `AppColors.redTint` | Background chips for negative changes / error banners. |
| **Warning Amber** | `#F59E0B` | `AppColors.warningAmber` | Stale-rate / offline / rate-limit warnings (distinct from Warm Gold CTAs). |
| **Info Blue** | `#3B82F6` | `AppColors.infoBlue` | Neutral info and news-item links; the only cool hue, used sparingly. |

### Gradients (composed only from locked/extended colors)
- **Brand Background:** `emeraldGlow → emeraldBg → emeraldDeep` (radial, center at 42% height)
- **Gold Metallic:** `goldLight → goldWarm → goldDeep` (top-left → bottom-right)

### Accessibility notes
- Text on **Warm Gold**: use `textDark` (white on gold fails contrast).
- Text on **Deep Emerald**: use `white` or `goldLight`.
- Never use Positive Mint / Negative Red for anything except financial direction and errors.

---

## 6. Logo & Asset Rules (v1.2: white launch experience)

The app is **white-first**: app icon background, native launch screen, animated splash, welcome/login/sign-up and home all sit on `AppColors.white` (or `surfaceSlate` for dashboard pages). Green is an accent (buttons, icons, links), not a background. `emeraldBg` remains the theme seed colour only.

| Asset | File | Use |
| :--- | :--- | :--- |
| Full logo (horizontal) | `assets/brand/logo_full.png` | App bars, auth screens, welcome screen |
| Full logo (stacked) | `assets/brand/logo_stacked.png` | Portrait layouts that need a taller logo |
| Logo mark | `assets/brand/logo_mark.png` | Coin + arrows only |
| Splash layers | `assets/brand/splash_{coin,arrow_green,arrow_gold,curren,see}.png` | Animated splash (`lib/screens/splash_screen.dart`). The coin and arrow layers share one square canvas centred on the coin. |
| Blank splash icon | `assets/brand/splash_blank.png` | Transparent Android 12 splash icon so the native splash stays plain white |
| App icon | `assets/icons/app_icon*.png` | Launcher icons on a white background |
| Welcome photo | `assets/images/money_lady.jpg` | Greyed-out background on the welcome screen |

"Powered by AB Finance" is defined once in `AppBrand.poweredBy` (`lib/constants/assets.dart`).
