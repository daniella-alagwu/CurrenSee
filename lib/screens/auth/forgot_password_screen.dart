import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:currensee/auth/auth_widgets.dart';
import 'package:currensee/constants/colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  bool _loading = false;
  bool _requestSubmitted = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _requestSubmitted = false;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _email.text.trim(),
      );
      if (mounted) setState(() => _requestSubmitted = true);
    } on FirebaseAuthException catch (error) {
   
      if (mounted && error.code == 'user-not-found') {
        setState(() => _requestSubmitted = true);
      } else if (mounted) {
        showAuthError(context, authErrorMessage(error));
      }
    } catch (error) {
      if (mounted) showAuthError(context, authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Reset your password',
      subtitle: 'Enter the email on your account and we’ll request a reset link.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AuthTextField(
              controller: _email,
              label: 'Email',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _sendResetLink(),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Enter your email';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            if (_requestSubmitted) ...[
              const SizedBox(height: 12),
              const Text(
                'If there’s a CurrenSee account for this email, a reset link has been requested. Check your inbox and Spam/Junk.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 20),
            GoldButton(
              label: _requestSubmitted ? 'Send link again' : 'Send reset link',
              isLoading: _loading,
              onPressed: _sendResetLink,
            ),
            const SizedBox(height: 8),
            Center(
              child: AuthLink(
                label: 'Back to log in',
                onPressed: _loading ? () {} : () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
