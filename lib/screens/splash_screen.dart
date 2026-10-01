import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/assets.dart';
import '../constants/colors.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.nextBuilder});

  final WidgetBuilder nextBuilder;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  static const double _lockW = 1043;
  static const double _lockH = 400;
  static const double _markSize = 400;
  static const Offset _coinCentreAtStart = Offset(_lockW / 2, _lockH / 2);
  static const Rect _curren = Rect.fromLTWH(392, 138.15, 426.27, 119.7);
  static const Rect _see = Rect.fromLTWH(826.27, 112.23, 207.48, 151.62);

  static const int _totalMs = 4200;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _totalMs),
  );

  Animation<double> _seg(int from, int to, Curve curve) => CurvedAnimation(
        parent: _c,
        curve: Interval(from / _totalMs, to / _totalMs, curve: curve),
      );

  late final Animation<double> _coin = _seg(0, 700, Curves.easeOutBack);
  late final Animation<double> _coinFade = _seg(0, 350, Curves.easeOut);
  late final Animation<double> _greenSpin = _seg(300, 1700, Curves.easeOutCubic);
  late final Animation<double> _goldSpin = _seg(450, 1850, Curves.easeOutCubic);
  late final Animation<double> _arrowFade = _seg(300, 800, Curves.easeOut);
  late final Animation<double> _shift = _seg(1900, 2900, Curves.easeInOutCubic);
  late final Animation<double> _currenOut = _seg(1900, 2900, Curves.easeInOutCubic);
  late final Animation<double> _seeOut = _seg(2000, 3000, Curves.easeInOutCubic);
  late final Animation<double> _poweredBy = _seg(3100, 3700, Curves.easeOut);

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _preloadAndPlay();
  }

  Future<void> _preloadAndPlay() async {
    
    try {
      await Future.wait([
        for (final asset in AppAssets.splashLayers)
          precacheImage(AssetImage(asset), context, onError: (_, __) {}),
      ]).timeout(const Duration(seconds: 3));
    } catch (_) {}
    if (!mounted) return;
    try {
      if (MediaQuery.disableAnimationsOf(context)) {
        _c.value = 1;
        await Future<void>.delayed(const Duration(milliseconds: 700));
      } else {
        await _c.forward();
      }
    } catch (_) {}
    _goNext();
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

 

  Widget _square(String asset, {double angle = 0, double scale = 1, double opacity = 1}) {
    return Positioned(
      left: 0,
      top: 0,
      width: _markSize,
      height: _markSize,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: scale,
            child: Image.asset(asset, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }


  Widget _word(String asset, Rect target, double t) {
    final dx = (_coinCentreAtStart.dx - target.center.dx) * (1 - t);
    return Positioned(
      left: target.left,
      top: target.top,
      width: target.width,
      height: target.height,
      child: Opacity(
        opacity: Curves.easeOut.transform((t * 5).clamp(0.0, 1.0)),
        child: Transform.translate(
          offset: Offset(dx, 0),
          child: Image.asset(asset, fit: BoxFit.fill),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final logoWidth = math.min(w * 0.88, 520.0);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final markDx = (_lockW / 2 - _markSize / 2) * (1 - _shift.value);
            final green = -1.5 * math.pi * (1 - _greenSpin.value);
            final gold = -1.5 * math.pi * (1 - _goldSpin.value);

            return Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: logoWidth,
                    height: logoWidth * _lockH / _lockW,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: _lockW,
                        height: _lockH,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Words sit *under* the mark so they emerge from
                            // behind the coin.
                            _word(AppAssets.splashCurren, _curren, _currenOut.value),
                            _word(AppAssets.splashSee, _see, _seeOut.value),
                            Positioned(
                              left: markDx,
                              top: 0,
                              width: _markSize,
                              height: _markSize,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  _square(
                                    AppAssets.splashArrowGreen,
                                    angle: green,
                                    scale: 0.6 + 0.4 * _greenSpin.value,
                                    opacity: _arrowFade.value,
                                  ),
                                  _square(
                                    AppAssets.splashArrowGold,
                                    angle: gold,
                                    scale: 0.6 + 0.4 * _goldSpin.value,
                                    opacity: _arrowFade.value,
                                  ),
                                  _square(
                                    AppAssets.splashCoin,
                                    scale: 0.5 + 0.5 * _coin.value,
                                    opacity: _coinFade.value,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Opacity(
                      opacity: _poweredBy.value,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - _poweredBy.value)),
                        child: const _PoweredBy(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PoweredBy extends StatelessWidget {
  const _PoweredBy();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Powered by ',
            style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w400),
          ),
          TextSpan(
            text: AppBrand.poweredBy,
            style: TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      style: TextStyle(fontSize: 14, letterSpacing: 0.6),
    );
  }
}
