import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'package:currensee/screens/auth/login_screen.dart';
import 'email_verification_gate.dart';
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
 
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.emeraldBg,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.goldWarm),
            ),
          );
        }
 
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return EmailVerificationGate(user: user);
      },
    );
  }
}
 