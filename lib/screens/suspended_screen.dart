import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:currensee/auth/auth_widgets.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/screens/home/widgets/chat_view.dart';
import 'package:currensee/services/api_client.dart';
import 'package:currensee/services/user_store.dart';

/// Shown instead of the app when the signed-in account is suspended.
/// The user can appeal to the admin from here; once an admin reactivates the
/// account, this screen detects it and lets the user into the app.
class SuspendedScreen extends StatefulWidget {
  const SuspendedScreen({super.key});

  @override
  State<SuspendedScreen> createState() => _SuspendedScreenState();
}

class _SuspendedScreenState extends State<SuspendedScreen> {
  Timer? _timer;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    // Notice a reactivation without the user having to do anything.
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _checkStatus(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus({bool silent = false}) async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final status = await ApiClient.getMyStatus();
      if (status != 'SUSPENDED') {
        // AuthGate listens to this and swaps back to the normal app.
        ApiClient.suspendedUid.value = null;
        return;
      }
      if (!silent && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('Your account is still suspended.'),
            behavior: SnackBarBehavior.floating,
          ));
      }
    } catch (e) {
      if (!silent && mounted) showAuthError(context, authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _logout() async {
    try {
      await UserStore.instance.signOut();
    } catch (_) {
      await FirebaseAuth.instance.signOut();
    }
    ApiClient.suspendedUid.value = null;
  }

  void _openAppeal() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SuspensionAppealScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.redTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.block_rounded,
                      size: 48, color: AppColors.negativeRed),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Account suspended',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted)),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Your CurrenSee account has been suspended, so you can\'t use the app right now.\n\n'
                  'If you think this is a mistake, or you\'d like your account reviewed, '
                  'contact support. Your message goes straight to an administrator, who can reactivate your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, height: 1.45, fontSize: 15),
                ),
                const SizedBox(height: 28),
                GoldButton(label: 'Contact support / Appeal', onPressed: _openAppeal),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _checking ? null : () => _checkStatus(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.forestGreen,
                      side: const BorderSide(color: AppColors.borderSlate),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.forestGreen))
                        : const Text('Check account status'),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _logout,
                  child: const Text('Log out',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chat with the admin. Everything sent here is tagged as an account suspension
/// appeal by the server, and admin replies show up in the same thread.
class SuspensionAppealScreen extends StatefulWidget {
  const SuspensionAppealScreen({super.key});

  @override
  State<SuspensionAppealScreen> createState() => _SuspensionAppealScreenState();
}

class _SuspensionAppealScreenState extends State<SuspensionAppealScreen> {
  @override
  void initState() {
    super.initState();
    ApiClient.suspendedUid.addListener(_onSuspensionChanged);
  }

  @override
  void dispose() {
    ApiClient.suspendedUid.removeListener(_onSuspensionChanged);
    super.dispose();
  }

  // Account got reactivated while the chat was open: close it so the app shows.
  void _onSuspensionChanged() {
    if (ApiClient.suspendedUid.value == null && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSlate,
      appBar: AppBar(title: const Text('Appeal suspension')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.redTint,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Text(
              'Explain why your account should be reactivated. '
              'Your message is sent to the administrator as an account suspension appeal.',
              style: TextStyle(color: AppColors.textDark, fontSize: 13, height: 1.35),
            ),
          ),
          Expanded(
            child: ChatView(
              mySender: 'USER',
              load: ApiClient.getMessages,
              send: ApiClient.submitSuspensionAppeal,
              emptyText: 'Write your appeal below. The administrator\'s reply will appear here.',
            ),
          ),
        ],
      ),
    );
  }
}