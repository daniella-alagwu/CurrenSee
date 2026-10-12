import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:currensee/screens/welcome_screen.dart';
import 'package:currensee/screens/suspended_screen.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';
import 'auth_loading_view.dart';
import 'email_verification_gate.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AuthLoadingView();
        }

        final user = snapshot.data;
        if (user == null) {

          SessionStore.clear();
          return const WelcomeScreen();
        }

        return ValueListenableBuilder<String?>(
          valueListenable: ApiClient.suspendedUid,
          builder: (context, suspendedUid, _) {
            if (suspendedUid == user.uid) return const SuspendedScreen();
            return EmailVerificationGate(key: ValueKey(user.uid), user: user);
          },
        );
      },
    );
  }
}