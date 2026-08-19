import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/soccer.dart';
import 'screens/auth_gate.dart';
import 'screens/home_shell.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(FairPlayLabApp(authService: await _startFirebase()));
}

/// Returns an [AuthService] once Firebase is ready, or null if it is not.
/// A coach on a bad connection should still get a working app, so failures
/// fall back to on-device storage instead of blocking startup.
Future<AuthService?> _startFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Sideline edits and match logs happen on fields with poor signal, so keep
    // a local cache and let Firestore sync when the connection returns.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    return AuthService();
  } on Object catch (error) {
    debugPrint('Firebase unavailable, falling back to local storage: $error');
    return null;
  }
}

class FairPlayLabApp extends StatelessWidget {
  const FairPlayLabApp({super.key, this.authService});

  /// When null the app runs entirely on-device with no sign-in.
  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    final auth = authService;

    return MaterialApp(
      title: SoccerConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: auth == null
          ? const FairPlayAppScope()
          : AuthGate(authService: auth),
    );
  }
}
