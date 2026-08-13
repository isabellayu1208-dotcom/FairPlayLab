import 'package:flutter/material.dart';
import 'models/soccer.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FairPlayLabApp());
}

class FairPlayLabApp extends StatelessWidget {
  const FairPlayLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: SoccerConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const FairPlayAppScope(),
    );
  }
}
