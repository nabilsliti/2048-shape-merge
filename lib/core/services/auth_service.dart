import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '282452142394-ge9je0vjtaetg6vg8aud6p3jjc43s46m.apps.googleusercontent.com',
    scopes: ['email'],
  );

  /// Last sign-in error for UI display (debug only)
  String? lastError;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    lastError = null;
    try {
      debugPrint('🔐 Google Sign-In: starting (explicit serverClientId)...');
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        lastError = 'Sign-In cancelled (googleUser==null)';
        debugPrint('🔐 Google Sign-In: $lastError');
        return null;
      }
      debugPrint('🔐 Google Sign-In: got user ${googleUser.email}');

      final googleAuth = await googleUser.authentication;
      debugPrint('🔐 Google Sign-In: got auth, idToken=${googleAuth.idToken != null}, accessToken=${googleAuth.accessToken != null}');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      debugPrint('🔐 Google Sign-In: success! uid=${result.user?.uid}');
      return result;
    } catch (e, st) {
      lastError = e.toString();
      debugPrint('🔐 Google Sign-In ERROR: $e');
      debugPrint('🔐 Stack: $st');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
