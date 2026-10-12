import 'dart:async';

import 'package:flutter/material.dart';
import '../constants/assets.dart';
import '../constants/colors.dart';
import 'auth_widgets.dart';

class AuthLoadingView extends StatefulWidget {
  const AuthLoadingView({super.key, this.errorMessage, this.onRetry, this.onSignOut});

  //pulse replacement for the logo mark
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onSignOut;

  @override
  State<AuthLoadingView> createState() => _AuthLoadingViewState();
}

class _AuthLoadingViewState extends State<AuthLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  Timer? _slowTimer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    // Only say something if it is genuinely taking a while.
    _slowTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.errorMessage;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: error == null
                      ? Tween<double>(begin: 0.55, end: 1).animate(
                          CurvedAnimation(parent: _pulse, curve: Curves.easeInOut))
                      : const AlwaysStoppedAnimation<double>(1),
                  child: Image.asset(AppAssets.logoMark, width: 88, height: 88),
                ),
                if (error != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textDark, fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  if (widget.onRetry != null)
                    GoldButton(label: 'Try again', onPressed: widget.onRetry),
                  if (widget.onSignOut != null)
                    AuthLink(label: 'Sign out', onPressed: widget.onSignOut!),
                ] else if (_slow) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'This is taking longer than usual. Please check your connection.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}