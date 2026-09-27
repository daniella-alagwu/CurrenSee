import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/auth/auth_widgets.dart';
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
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      // AuthGate listens to authStateChanges and swaps in HomeScreen.
    } catch (e) {
      if (mounted) showAuthError(context, authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
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
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Enter your email';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
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
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter your password' : null,
              suffix: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                ),
                color: AppColors.textMuted,
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 24),
            GoldButton(label: 'Log in', isLoading: _loading, onPressed: _login),
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
