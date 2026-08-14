import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/soccer.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(FairPlayLabApp(useFirebase: await _startFirebase()));
}

/// Returns whether Firestore can be used. A coach on a bad connection should
/// still get a working app, so failures fall back to on-device storage.
Future<bool> _startFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } on Object catch (error) {
    debugPrint('Firebase unavailable, falling back to local storage: $error');
    return false;
  }
}

class FairPlayLabApp extends StatelessWidget {
  const FairPlayLabApp({super.key, required this.useFirebase});

  final bool useFirebase;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: SoccerConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: FairPlayAppScope(useFirebase: useFirebase),
    );
  }
}
