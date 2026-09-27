import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth/auth_gate.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const CurrenSeeApp());
}

class CurrenSeeApp extends StatelessWidget {
  const CurrenSeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => FlutterNativeSplash.remove(),
    );

    return MaterialApp(
      title: 'CurrenSee',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: SplashScreen(nextBuilder: (_) => const AuthGate()),
    );
  }
}
