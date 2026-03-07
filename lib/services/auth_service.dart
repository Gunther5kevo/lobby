import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

/// Wraps Firebase Auth and Google Sign-In.
/// All methods throw [FirebaseAuthException] on failure —
/// catch in the UI layer and map to user-facing messages.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _google = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  // ── Current user ───────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes. Emits null when signed out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Email / password ───────────────────────────────────────────

  /// Creates a new account and writes the initial Firestore profile.
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String handle,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update Firebase Auth display name
    await cred.user!.updateDisplayName(displayName);

    // Write initial Firestore profile
    await FirestoreService().createUserProfile(
      uid: cred.user!.uid,
      displayName: displayName,
      handle: handle,
      email: email,
      avatarUrl: null,
    );

    return cred;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ── Google sign-in ─────────────────────────────────────────────

  /// Signs in with Google. Creates a Firestore profile on first login.
  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _google.signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken:     googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);

    // Create profile only on first sign-in
    if (cred.additionalUserInfo?.isNewUser == true) {
      final handle = _handleFromName(googleUser.displayName ?? 'user');
      await FirestoreService().createUserProfile(
        uid:         cred.user!.uid,
        displayName: googleUser.displayName ?? 'Player',
        handle:      handle,
        email:       googleUser.email,
        avatarUrl:   googleUser.photoUrl,
      );
    }

    return cred;
  }

  // ── Sign out ───────────────────────────────────────────────────

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _google.signOut(),
    ]);
  }

  // ── Password reset ─────────────────────────────────────────────

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Helpers ────────────────────────────────────────────────────

  /// Converts a display name into a lowercased handle with no spaces.
  String _handleFromName(String name) {
    final clean = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return '#${clean}_${DateTime.now().millisecondsSinceEpoch % 9999}';
  }
}

// ── Auth error messages ────────────────────────────────────────────────────

/// Converts a [FirebaseAuthException] code into a human-readable string.
String authErrorMessage(FirebaseAuthException e) {
  return switch (e.code) {
    'user-not-found'        => 'No account found with that email.',
    'wrong-password'        => 'Incorrect password.',
    'email-already-in-use'  => 'That email is already registered.',
    'invalid-email'         => 'Please enter a valid email address.',
    'weak-password'         => 'Password must be at least 6 characters.',
    'too-many-requests'     => 'Too many attempts. Please try again later.',
    'network-request-failed'=> 'No internet connection.',
    _                       => 'Something went wrong. Please try again.',
  };
}