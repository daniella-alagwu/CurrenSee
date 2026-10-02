# CurrenSee — Changelog

## [Unreleased]

### Added
- `blueprint.md`: app structure, screens, features, open decisions, roadmap, team conventions — Daniella
- `CHANGELOG.md`: this file — Daniella
- Animated splash screen (`lib/screens/splash_screen.dart`): full light logo, breathing scale, two light sweeps, tagline, gold progress line, 4.4s then 600ms fade — Daniella
- Splash footer "Commissioned by ABC Finance Ltd." (`lib/screens/splash_screen.dart`) — Daniella
- `assets/brand/splash_native.png` (full light logo, 1000px) for the native splash — Daniella
- Theme (`lib/theme/app_theme.dart`) and asset constants (`lib/constants/assets.dart`) — Daniella
- Launcher icons (iOS, Android adaptive, Android 13 themed) generated from the logo (`assets/icons/`, `pubspec.yaml`) — Daniella
- Logo variants: full light, full dark (white "Curren"), mark, Android 12 splash (`assets/brand/`) — Daniella
- Widget test for splash hand-over (`test/widget_test.dart`) — Daniella

### Changed
- Native splash switched from emerald + mark to white + full light logo (`pubspec.yaml`) — Daniella
- Splash background moved from emerald to `AppColors.splashLight` so the light logo is legible (`lib/screens/splash_screen.dart`) — Daniella
- `pubspec.yaml` merged: `flutter_native_splash`, `flutter_launcher_icons`, asset folders — Daniella

### Brand
- Locked palette documented in `BRAND.md` and mapped 1:1 to `lib/constants/colors.dart` — Daniella
- Proposed v1.1 extended palette (`emeraldDeep`, `emeraldGlow`, `logoGreen`, `goldDeep`, `borderSlate`, `mintTint`, `redTint`, `warningAmber`, `infoBlue`); **pending client approval** — Daniella
- Added `AppColors.splashLight` gradient (white to Surface Slate) and a Splash Screen Spec in `BRAND.md` §8 — Daniella

### Removed
- Earlier emerald-background splash and its glow/pop-in animation, replaced by the animation above — Daniella

---

## History

| Version | Date | Summary |
| :--- | :--- | :--- |
| 1.0.0+1 (pubspec, pre-release) | 2026-09-23 | Project created; Foundation phase (see [Unreleased]) |