import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/auth/auth_widgets.dart';
import 'package:currensee/auth/social_login_buttons.dart';
import 'package:currensee/services/api_client.dart';

import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    Future<void> signIn() => FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );

    try {
      try {
        await signIn();
      } on FirebaseAuthException catch (e) {
        if (e.code != 'user-disabled') rethrow;
        // Suspended accounts must still be able to sign in so they can see the
        // suspended page and appeal. Ask the server to re-enable sign-in, retry once.
        await ApiClient.restoreSignIn(_email.text.trim());
        await signIn();
      }
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        showAuthError(context, authErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Log in to see live rates and your conversions.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AuthTextField(
              controller: _email,
              label: 'Email',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Enter your email';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _password,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _login(),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter your password' : null,
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                color: AppColors.textMuted,
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: AuthLink(
                label: 'Forgot password?',
                onPressed: _loading
                    ? () {}
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ForgotPasswordScreen(
                            initialEmail: _email.text.trim(),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            GoldButton(label: 'Log in', isLoading: _loading, onPressed: _login),
            const SocialLoginButtons(),
            const SizedBox(height: 8),
            Center(
              child: AuthLink(
                label: "Don't have an account? Sign up",
                onPressed: _loading
                    ? () {}
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}