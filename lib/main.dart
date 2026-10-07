import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'constants/colors.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'auth/auth_gate.dart';
import 'screens/admin/admin_home.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

 
  ErrorWidget.builder = (details) => Material(
        color: AppColors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Something went wrong.\n\n${details.exceptionAsString()}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDark, fontSize: 14),
            ),
          ),
        ),
      );

  Object? startupError;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    startupError = e;
  }

  runApp(CurrenSeeApp(startupError: startupError));

  FlutterNativeSplash.remove();
}

class CurrenSeeApp extends StatelessWidget {
  const CurrenSeeApp({super.key, this.startupError});

  final Object? startupError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CurrenSee',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      onGenerateRoute: (settings) {
        if (settings.name == '/admin') {
          return MaterialPageRoute<void>(
            builder: (_) => const AdminHome(),
            settings: settings,
          );
        }
        return null;
      },
      home: startupError != null
          ? _StartupErrorScreen(error: startupError!)
          : SplashScreen(nextBuilder: (_) => const AuthGate()),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'CurrenSee could not start.\n\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDark, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}
