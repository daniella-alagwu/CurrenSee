import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Social sign-in through Firebase Authentication.

class SocialAuthService {
  SocialAuthService._();

  static Future<UserCredential> signInWithGoogle() {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile')
      ..setCustomParameters({'prompt': 'select_account'});
    return _signIn(provider);
  }

  static Future<UserCredential> _signIn(AuthProvider provider) {
    final auth = FirebaseAuth.instance;
    return kIsWeb ? auth.signInWithPopup(provider) : auth.signInWithProvider(provider);
  }

  //for when the user closes the Google window.
  static bool isCancelled(Object error) =>
      error is FirebaseAuthException &&
      const {
        'canceled',
        'cancelled',
        'user-cancelled',
        'popup-closed-by-user',
        'web-context-canceled',
        'web-context-cancelled',
      }.contains(error.code);
}