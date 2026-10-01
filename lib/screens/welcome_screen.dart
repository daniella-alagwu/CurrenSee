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
    final size = MediaQuery.sizeOf(context);

    
    final imageHeight = size.height * 0.48;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              
              SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      AppAssets.moneyLady,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),

                    
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.transparent,
                            AppColors.white.withValues(alpha: 0.18),
                            AppColors.white.withValues(alpha: 0.82),
                          ],
                          stops: const [
                            0.0,
                            0.35,
                            0.72,
                            1.0,
                          ],
                        ),
                      ),
                    ),

                  
                    Positioned(
                      top: 58,
                      left: 24,
                      right: 24,
                      child: Center(
                        child: Image.asset(
                          AppAssets.logoFull,
                          width: size.width * 0.48,
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

           
              Transform.translate(
                offset: const Offset(0, -34),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26, 30, 26, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 440,
                        ),
                        child: Column(
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

                            const SizedBox(height: 18),

                            const Text(
                              'Currency rates,\nmade simple.',
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 35,
                                height: 1.08,
                                letterSpacing: -0.8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 14),

                            const Text(
                              'Track live exchange rates, convert currencies '
                              'instantly, and keep your conversions organised '
                              'in one simple place.',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 15.5,
                                height: 1.55,
                              ),
                            ),

                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _FeatureItem(
                                  title: 'Live rates',
                                  icon: Icons.show_chart_rounded,
                                ),
                                const SizedBox(width: 10),
                                _FeatureItem(
                                  title: 'Instant',
                                  icon: Icons.bolt_rounded,
                                ),
                                const SizedBox(width: 10),
                                _FeatureItem(
                                  title: 'History',
                                  icon: Icons.history_rounded,
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),
                            GoldButton(
                              label: 'Create An Account',
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                            //login
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

                            const SizedBox(height: 22),

                            Center(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Powered by ',
                                    ),
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
                        ),
                      ),
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
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 10),
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
              size: 18,
              color: AppColors.forestGreen,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 12,
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

