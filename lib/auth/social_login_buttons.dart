import 'package:flutter/material.dart';
import 'package:currensee/auth/auth_widgets.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/services/social_auth_service.dart';

//fo sign up with google
class SocialLoginButtons extends StatefulWidget {
  const SocialLoginButtons({super.key, this.googleLabel = 'Continue with Google'});

  final String googleLabel;

  @override
  State<SocialLoginButtons> createState() => _SocialLoginButtonsState();
}

class _SocialLoginButtonsState extends State<SocialLoginButtons> {
  bool _busy = false;

  Future<void> _google() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await SocialAuthService.signInWithGoogle();
      // AuthGate reacts to the new session; just close the login/sign-up page.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted && !SocialAuthService.isCancelled(e)) {
        showAuthError(context, authErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(children: const [
          Expanded(child: Divider(color: AppColors.borderSlate)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('or', style: TextStyle(color: AppColors.textMuted)),
          ),
          Expanded(child: Divider(color: AppColors.borderSlate)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _busy ? null : _google,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textDark,
              side: const BorderSide(color: AppColors.borderSlate),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forestGreen),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderSlate),
                        ),
                        child: const Text('G',
                            style: TextStyle(
                                color: Color(0xFF4285F4),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                height: 1)),
                      ),
                      const SizedBox(width: 10),
                      Text(widget.googleLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}