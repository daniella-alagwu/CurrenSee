import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'auth_widgets.dart';
import 'package:currensee/screens/home/home_screen.dart';
import '../services/api_client.dart';
import 'verify_email_screen.dart';


class EmailVerificationGate extends StatefulWidget {
  const EmailVerificationGate({super.key, required this.user});

  final User user;

  @override
  State<EmailVerificationGate> createState() => _EmailVerificationGateState();
}

class _EmailVerificationGateState extends State<EmailVerificationGate> {
  bool _verified = false;
  bool _profileReady = false;
  bool _profileSaving = false;
  bool _checking = false;
  String? _profileError;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _check();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _check());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking || _profileReady) return;
    _checking = true;
    try {
   
      await FirebaseAuth.instance.currentUser?.reload();
      final refreshed = FirebaseAuth.instance.currentUser;
      if (refreshed == null || !refreshed.emailVerified) {
        return;
      }

      _pollTimer?.cancel();
      if (mounted) {
        setState(() {
          _verified = true;
          _profileSaving = true;
          _profileError = null;
        });
      }

      await ApiClient.registerProfile();
      if (mounted) {
        setState(() {
          _profileReady = true;
          _profileSaving = false;
        });
      }
    } catch (error) {
      if (mounted && _verified) {
        setState(() {
          _profileSaving = false;
          _profileError =
              'Your email is verified, but account setup failed: $error';
        });
      }
    } finally {
      _checking = false;
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_profileReady) return const HomeScreen();
    if (_verified) {
      return Scaffold(
        backgroundColor: AppColors.emeraldBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _profileSaving ? 'Setting up your account…' : (_profileError ?? 'Setting up your account…'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.white, fontSize: 16),
                ),
                if (!_profileSaving) ...[
                  const SizedBox(height: 16),
                  GoldButton(label: 'Try again', onPressed: _check),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return VerifyEmailScreen(onCheckNow: _check);
  }
}
