import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/rtdb_service.dart';
import '../services/fcm_service.dart';

// ── Service singletons ─────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final rtdbServiceProvider = Provider<RtdbService>((ref) => RtdbService());
final fcmServiceProvider  = Provider<FcmService>((ref)  => FcmService());

// ── Auth state stream ──────────────────────────────────────────────────────

/// Emits the current [User] when signed in, null when signed out.
/// This is the single source of truth for auth state across the whole app.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Convenience: throws if called when no user is signed in.
final currentUserProvider = Provider<User>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) throw StateError('currentUserProvider called while signed out');
  return user;
});

/// The current user's UID, or null if signed out.
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

/// The current user's UID — throws if called while signed out.
/// Use this inside notifiers that are only alive when the user is signed in.
final currentUidRequiredProvider = Provider<String>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) throw StateError('currentUidRequiredProvider: not signed in');
  return uid;
});

// ── Sign-in actions ────────────────────────────────────────────────────────

/// Tracks loading + error state for any auth action.
class AuthActionState {
  const AuthActionState({
    this.isLoading = false,
    this.error,
  });
  final bool isLoading;
  final String? error;

  AuthActionState copyWith({bool? isLoading, String? error}) =>
      AuthActionState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthActionNotifier extends StateNotifier<AuthActionState> {
  AuthActionNotifier(this._ref) : super(const AuthActionState());

  final Ref _ref;

  AuthService get _auth => _ref.read(authServiceProvider);
  RtdbService get _rtdb => _ref.read(rtdbServiceProvider);
  FcmService  get _fcm  => _ref.read(fcmServiceProvider);

  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String handle,
  }) async {
    state = const AuthActionState(isLoading: true);
    try {
      final cred = await _auth.registerWithEmail(
        email:       email,
        password:    password,
        displayName: displayName,
        handle:      handle,
      );
      await _postSignIn(cred.user!.uid);
      state = const AuthActionState();
      return true;
    } on FirebaseAuthException catch (e) {
      state = AuthActionState(error: authErrorMessage(e));
      return false;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AuthActionState(isLoading: true);
    try {
      final cred = await _auth.signInWithEmail(email: email, password: password);
      await _postSignIn(cred.user!.uid);
      state = const AuthActionState();
      return true;
    } on FirebaseAuthException catch (e) {
      state = AuthActionState(error: authErrorMessage(e));
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = const AuthActionState(isLoading: true);
    try {
      final cred = await _auth.signInWithGoogle();
      if (cred == null) {
        state = const AuthActionState(); // cancelled
        return false;
      }
      await _postSignIn(cred.user!.uid);
      state = const AuthActionState();
      return true;
    } on FirebaseAuthException catch (e) {
      state = AuthActionState(error: authErrorMessage(e));
      return false;
    }
  }

  Future<void> signOut() async {
    final uid = _ref.read(currentUidProvider);
    if (uid != null) {
      await _fcm.deleteToken(uid);
      await _rtdb.goOffline(uid);
    }
    await _auth.signOut();
  }

  /// Post-sign-in tasks: set presence online + register FCM token.
  Future<void> _postSignIn(String uid) async {
    await Future.wait([
      _rtdb.goOnline(uid),
      _fcm.init(uid),
    ]);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authActionProvider =
    StateNotifierProvider<AuthActionNotifier, AuthActionState>((ref) {
  return AuthActionNotifier(ref);
});