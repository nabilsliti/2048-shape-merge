import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shape_merge/core/services/app_logger.dart';

const _log = AppLogger('Auth');

/// Server (web) client ID — used by the native Sign-In SDK to mint an
/// id_token that Firebase can verify.
const _serverClientId =
    '282452142394-ge9je0vjtaetg6vg8aud6p3jjc43s46m.apps.googleusercontent.com';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Initialised once via [warmUp] before the first interactive
  /// `authenticate()` call (required by the v7+ singleton API).
  bool _initialized = false;

  /// Last sign-in error for UI display (debug only)
  String? lastError;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> _ensureInitialised() async {
    if (_initialized) return;
    await _googleSignIn.initialize(serverClientId: _serverClientId);
    _initialized = true;
  }

  /// Pre-initialise the Google Sign-In plugin and try a silent sign-in so
  /// the first interactive `authenticate()` doesn't pay the native init
  /// cost (platform channel registration + Play Services wake-up).
  /// Safe to fire-and-forget at boot.
  Future<void> warmUp() async {
    try {
      await _ensureInitialised();
      // v7: silent sign-in is now `attemptLightweightAuthentication`.
      // Returns null if no cached account is available — never throws.
      await _googleSignIn.attemptLightweightAuthentication();
      _log.debug('Google Sign-In: warm-up complete');
    } catch (e) {
      _log.debug('Google Sign-In warm-up skipped: $e');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    lastError = null;
    try {
      await _ensureInitialised();
      _log.info('Google Sign-In: starting...');

      // v7: `authenticate()` replaces `signIn()`. It throws on cancel
      // (GoogleSignInException with code `canceled`) instead of returning null.
      final GoogleSignInAccount googleUser;
      try {
        googleUser = await _googleSignIn.authenticate(scopeHint: const ['email']);
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          _log.info('Google Sign-In: cancelled by user');
          return null;
        }
        rethrow;
      }
      _log.info('Google Sign-In: got user ${googleUser.email}');

      // v7: `authentication` is now a sync getter exposing only idToken.
      // Firebase only needs the idToken; an accessToken is not required for
      // GoogleAuthProvider.credential.
      final idToken = googleUser.authentication.idToken;
      _log.debug('Google Sign-In: got auth, idToken=${idToken != null}');

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      final result = await _auth.signInWithCredential(credential);
      _log.info('Google Sign-In: success! uid=${result.user?.uid}');
      return result;
    } catch (e, st) {
      lastError = e.toString();
      _log.error('Google Sign-In failed', error: e, stack: st);
      return null;
    }
  }

  Future<void> signOut() async {
    if (_initialized) {
      // v7: `signOut()` is now async-returning Future<void> on the singleton
      // and `disconnect()` is recommended to also revoke scopes. We only
      // sign out here so the next call re-prompts cleanly.
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }
}
