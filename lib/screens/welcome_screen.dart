import 'package:flutter/material.dart';

import '../auth/auth_widgets.dart';
import '../constants/assets.dart';
import '../constants/colors.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            if (isDesktop) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 24,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 11,
                          child: _buildImagePanel(
                            context,
                            desktop: true,
                          ),
                        ),
                        const SizedBox(width: 44),
                        Expanded(
                          flex: 9,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 470,
                              ),
                              child: _buildContent(
                                context,
                                compact: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final imageHeight =
                (constraints.maxHeight * 0.36)
                    .clamp(210.0, 320.0)
                    .toDouble();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: _buildImagePanel(
                      context,
                      desktop: false,
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -24),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 22,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        26,
                        24,
                        24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 470,
                          ),
                          child: _buildContent(
                            context,
                            compact: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImagePanel(
    BuildContext context, {
    required bool desktop,
  }) {
    if (!desktop) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.moneyLady,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.04),
                  Colors.transparent,
                  AppColors.white.withValues(alpha: 0.8),
                ],
                stops: const [0, 0.58, 1],
              ),
            ),
          ),
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: Center(
              child: Image.asset(
                AppAssets.logoFull,
                width: MediaQuery.sizeOf(context).width * 0.48,
                height: 58,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Image.asset(
                AppAssets.moneyLady,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              ),
            ),
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Center(
                child: Image.asset(
                  AppAssets.logoFull,
                  width: constraints.maxWidth * 0.58,
                  height: 58,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required bool compact,
  }) {
    final headingSize = compact ? 32.0 : 35.0;
    final sectionGap = compact ? 12.0 : 18.0;
    final featureGap = compact ? 16.0 : 20.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.forestGreen,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        SizedBox(height: sectionGap),
        Text(
          'Currency rates,\nmade simple.',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: headingSize,
            height: 1.08,
            letterSpacing: -0.8,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: compact ? 10 : 14),
        const Text(
          'Track live exchange rates, convert currencies instantly, '
          'and keep your conversions organised in one simple place.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        SizedBox(height: featureGap),
        const Row(
          children: [
            _FeatureItem(
              title: 'Live rates',
              icon: Icons.show_chart_rounded,
            ),
            SizedBox(width: 8),
            _FeatureItem(
              title: 'Instant',
              icon: Icons.bolt_rounded,
            ),
            SizedBox(width: 8),
            _FeatureItem(
              title: 'History',
              icon: Icons.history_rounded,
            ),
          ],
        ),
        SizedBox(height: compact ? 20 : 26),
        SizedBox(
          width: double.infinity,
          child: GoldButton(
            label: 'Create An Account',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RegisterScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LoginScreen(),
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.textDark,
              side: const BorderSide(
                color: AppColors.borderSlate,
                width: 1.3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'I already have an account',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 16 : 22),
        Center(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Powered by '),
                TextSpan(
                  text: AppBrand.poweredBy,
                  style: const TextStyle(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String title;
  final IconData icon;

  const _FeatureItem({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.borderSlate.withValues(alpha: 0.55),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: AppColors.forestGreen,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}