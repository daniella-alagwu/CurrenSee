import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'auth_loading_view.dart';
import 'package:currensee/screens/admin/admin_home.dart';
import 'package:currensee/screens/main_shell.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';
import 'complete_profile_screen.dart';
import 'verify_email_screen.dart';

class EmailVerificationGate extends StatefulWidget {
  const EmailVerificationGate({super.key, required this.user});

  final User user;

  @override
  State<EmailVerificationGate> createState() => _EmailVerificationGateState();
}

class _EmailVerificationGateState extends State<EmailVerificationGate> {
  bool _booting = true; //reading saved session
  bool _verified = false;
  bool _profileReady = false;
  bool _isAdmin = false;
  bool _needsSetup = false;
  bool _profileSaving = false;
  bool _checking = false;
  String? _profileError;
  Timer? _pollTimer;


  static const _revokedCodes = {
    'user-token-expired',
    'invalid-user-token',
    'user-not-found',
    'user-disabled',
  };

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final saved = await SessionStore.load(widget.user.uid);
    if (!mounted) return;


    if (saved != null && widget.user.emailVerified) {
      setState(() {
        _booting = false;
        _verified = true;
        _profileReady = true;
        _isAdmin = saved.isAdmin;
      });
      _revalidate();
      return;
    }

    setState(() => _booting = false);
    _check();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer ??= Timer.periodic(const Duration(seconds: 3), (_) => _check());
  }

  // for users signed in with Google
  bool get _isSocial =>
      widget.user.providerData.any((p) => p.providerId != 'password');

  //The user's row in db /null if it doesn't exist yet.
  Future<Map<String, dynamic>?> _fetchProfile() async {
    try {
      final data = await ApiClient.getCurrentUser();
      return data['user'] as Map<String, dynamic>?;
    } on ApiException catch (e) {
      if (e.code == 'PROFILE_NOT_FOUND' || e.statusCode == 404) return null;
      rethrow;
    }
  }

  void _finishSetup() {
    if (!mounted) return;
    setState(() => _needsSetup = false);
    _check();
  }


  Future<void> _revalidate() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
    } on FirebaseAuthException catch (e) {
      if (_revokedCodes.contains(e.code)) {
        await SessionStore.clear();
        await FirebaseAuth.instance.signOut();
        return;
      }
      // Any other error, to keep the saved session
    } catch (_) {}

    try {
      final profile = await _fetchProfile();
      if (!mounted) return;

      if (profile == null) {
        // Profile no longer exists
        await SessionStore.clear();
        setState(() {
          _profileReady = false;
          _verified = false;
        });
        _check();
        _startPolling();
        return;
      }

      if ('${profile['status']}'.toUpperCase() == 'SUSPENDED') {
        ApiClient.suspendedUid.value = widget.user.uid;
        return;
      }

      final token = await FirebaseAuth.instance.currentUser?.getIdTokenResult(true);
      final isAdmin = token?.claims?['admin'] == true;
      await SessionStore.save(widget.user.uid, isAdmin: isAdmin);
      if (mounted && isAdmin != _isAdmin) setState(() => _isAdmin = isAdmin);
    } catch (_) {
      // Offline or server hiccup: stay signed in with what we have.
    }
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
      _pollTimer = null;
      if (mounted) {
        setState(() {
          _verified = true;
          _profileSaving = true;
          _profileError = null;
        });
      }

      final profile = await _fetchProfile();

      // Suspended: AuthGate swaps this screen for the suspended page.
      if (profile != null && '${profile['status']}'.toUpperCase() == 'SUSPENDED') {
        ApiClient.suspendedUid.value = refreshed.uid;
        return;
      }

      // First Google/Facebook sign-in: we still need their country and currency.
      if (_isSocial && (profile == null || profile['countryCode'] == null)) {
        if (mounted) {
          setState(() {
            _needsSetup = true;
            _profileSaving = false;
          });
        }
        return;
      }

      await ApiClient.registerProfile();
      final tokenResult = await refreshed.getIdTokenResult(true);
      final isAdmin = tokenResult.claims?['admin'] == true;
      await SessionStore.save(refreshed.uid, isAdmin: isAdmin);
      if (mounted) {
        setState(() {
          _profileReady = true;
          _profileSaving = false;
          _isAdmin = isAdmin;
        });
      }
    } catch (error) {
      debugPrint('Account setup failed: $error');
      if (mounted && _verified) {
        setState(() {
          _profileSaving = false;
          _profileError =
              'We couldn\'t finish setting up your account. Check your connection and try again.';
        });
      }
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) return const AuthLoadingView();
    if (_profileReady) {
      return _isAdmin ? const AdminHome() : const MainShell();
    }
    if (_needsSetup) {
      return CompleteProfileScreen(onSaved: _finishSetup);
    }
    if (_verified) {
      return AuthLoadingView(
        errorMessage: _profileSaving ? null : _profileError,
        onRetry: _profileSaving ? null : _check,
        onSignOut: _profileSaving ? null : () => FirebaseAuth.instance.signOut(),
      );
    }
    return VerifyEmailScreen(onCheckNow: _check);
  }
}