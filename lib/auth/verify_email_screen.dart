import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'auth_widgets.dart';
import 'verify_otp_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.onCheckNow});


  final Future<void> Function() onCheckNow;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _resendCooldown = Duration(seconds: 45);

  bool _sending = false;
  bool _checking = false;
  int _secondsLeft = 0;
  Timer? _cooldownTimer;

  String get _email => FirebaseAuth.instance.currentUser?.email ?? 'your email';

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _secondsLeft = _resendCooldown.inSeconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) {
        _startCooldown();
        showAuthError(context, 'Verification link sent.');
      }
    } catch (e) {
      if (mounted) showAuthError(context, authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _checkNow() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await widget.onCheckNow();
    } catch (e) {
      if (mounted) showAuthError(context, authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _useOtp() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => VerifyOtpScreen(onVerified: widget.onCheckNow),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Check your email or spam',
      subtitle: "We sent a verification link to $_email.",
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSlate,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSlate),
            ),
            child: Row(
              children: [
                const Icon(Icons.mark_email_unread_outlined,
                    color: AppColors.forestGreen),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Open the link on this device, then come back here.',
                    style: TextStyle(color: AppColors.textDark, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GoldButton(
            label: "I've verified — continue",
            isLoading: _checking,
            onPressed: _checkNow,
          ),
          const SizedBox(height: 12),
          AuthLink(
            label: _secondsLeft > 0
                ? 'Resend link in ${_secondsLeft}s'
                : (_sending ? 'Sending…' : 'Resend verification link'),
            onPressed: (_secondsLeft > 0 || _sending) ? () {} : _resend,
          ),
          const SizedBox(height: 4),
          AuthLink(
            label: 'Verify with a 6-digit email code',
            onPressed: _checking || _sending ? () {} : _useOtp,
          ),
          const SizedBox(height: 4),
          AuthLink(
            label: 'Use a different account',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
    );
  }
}
