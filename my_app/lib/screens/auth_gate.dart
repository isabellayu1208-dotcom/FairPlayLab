import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'home_shell.dart';
import 'sign_in_screen.dart';

/// Shows the sign-in form until a coach is signed in, then hands their user id
/// to the app so Firestore reads and writes stay scoped to their own squad.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return SignInScreen(authService: authService);
        }

        return FairPlayAppScope(
          // Rebuild the controller from scratch when the coach changes.
          key: ValueKey(user.uid),
          teamId: user.uid,
          accountEmail: user.email,
          onSignOut: authService.signOut,
        );
      },
    );
  }
}
