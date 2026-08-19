import 'package:firebase_auth/firebase_auth.dart';

/// Thrown with a message that is safe to show a coach directly.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Wraps [FirebaseAuth] so screens never deal with Firebase error codes.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) {
    return _run(
      () => _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  Future<void> createAccount({required String email, required String password}) {
    return _run(
      () => _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _run(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    }
  }

  String _messageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address does not look right.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account already exists for that email. Try signing in.';
      case 'weak-password':
        return 'Use at least 6 characters for your password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'network-request-failed':
        return 'No connection. Check your network and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a minute, then try again.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled for this Firebase project yet.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }
}
