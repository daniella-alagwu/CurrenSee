import 'package:flutter/material.dart';
import '../constants/assets.dart';
import '../constants/colors.dart';

/// Animated splash: glow pulse -> mark pops in -> wordmark slides up ->
/// tagline + gold progress bar -> fades to [nextBuilder].
/// Requires Flutter 3.27+ (uses Color.withValues).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.nextBuilder});

  final WidgetBuilder nextBuilder;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 2800);

  late final AnimationController _c =
  AnimationController(vsync: this, duration: _total);

  late final Animation<double> _glow = CurvedAnimation(
      parent: _c, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
  late final Animation<double> _markScale = Tween(begin: 0.55, end: 1.0)
      .animate(CurvedAnimation(
      parent: _c,
      curve: const Interval(0.05, 0.45, curve: Curves.easeOutBack)));
  late final Animation<double> _markFade = CurvedAnimation(
      parent: _c, curve: const Interval(0.05, 0.3, curve: Curves.easeIn));
  late final Animation<double> _wordFade = CurvedAnimation(
      parent: _c, curve: const Interval(0.35, 0.6, curve: Curves.easeOut));
  late final Animation<Offset> _wordSlide =
  Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _c,
          curve: const Interval(0.35, 0.6, curve: Curves.easeOutCubic)));
  late final Animation<double> _tagFade = CurvedAnimation(
      parent: _c, curve: const Interval(0.55, 0.75, curve: Curves.easeOut));
  late final Animation<double> _progress = CurvedAnimation(
      parent: _c, curve: const Interval(0.5, 1.0, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(_goNext);
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (ctx, _, __) => widget.nextBuilder(ctx),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final markSize = w * 0.36;

    return Scaffold(
      backgroundColor: AppColors.emeraldBg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandBackground),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Column(
              children: [
                const Spacer(flex: 5),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Soft gold glow behind the mark
                    Container(
                      width: markSize * 1.9 * (0.7 + 0.3 * _glow.value),
                      height: markSize * 1.9 * (0.7 + 0.3 * _glow.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          AppColors.goldLight
                              .withValues(alpha: 0.22 * _glow.value),
                          AppColors.goldLight.withValues(alpha: 0.0),
                        ]),
                      ),
                    ),
                    Opacity(
                      opacity: _markFade.value,
                      child: Transform.scale(
                        scale: _markScale.value,
                        child: Image.asset(AppAssets.logoMark,
                            width: markSize, fit: BoxFit.contain),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _wordFade,
                  child: SlideTransition(
                    position: _wordSlide,
                    child: Image.asset(AppAssets.logoFullDark,
                        width: w * 0.62, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: _tagFade,
                  child: const Text(
                    'Live rates. Clear insight.',
                    style: TextStyle(
                      color: AppColors.goldPrimary,
                      fontSize: 14,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(flex: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: SizedBox(
                    width: w * 0.32,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress.value,
                        minHeight: 3,
                        backgroundColor:
                        AppColors.forestGreen.withValues(alpha: 0.5),
                        valueColor:
                        const AlwaysStoppedAnimation(AppColors.goldWarm),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}