import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_detection_service.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'firestore_providers.dart';

// ── Service ────────────────────────────────────────────────────────────────

final gameDetectionServiceProvider =
    Provider<GameDetectionService>((ref) => GameDetectionService());

// ── Installed game scan ────────────────────────────────────────────────────

/// Scans the device for installed games. Android only — empty list on iOS.
/// Cached as a FutureProvider so it only runs once per session.
final installedGamesProvider =
    FutureProvider<List<DetectedGame>>((ref) async {
  return ref.watch(gameDetectionServiceProvider).detectInstalledGames();
});

// ── OAuth connection state ─────────────────────────────────────────────────

enum OAuthStatus { idle, connecting, success, error }

class GameOAuthState {
  const GameOAuthState({
    this.status = OAuthStatus.idle,
    this.lastConnected,
    this.error,
  });

  final OAuthStatus status;
  final String? lastConnected; // game name that just connected
  final String? error;

  GameOAuthState copyWith({
    OAuthStatus? status,
    String? lastConnected,
    String? error,
  }) =>
      GameOAuthState(
        status:        status        ?? this.status,
        lastConnected: lastConnected ?? this.lastConnected,
        error:         error         ?? this.error,
      );
}

class GameOAuthNotifier extends StateNotifier<GameOAuthState> {
  GameOAuthNotifier(this._ref) : super(const GameOAuthState());

  final Ref _ref;

  GameDetectionService get _detection =>
      _ref.read(gameDetectionServiceProvider);
  FirestoreService get _fs => _ref.read(firestoreServiceProvider);
  String get _myUid => _ref.read(currentUidRequiredProvider);

  // ── Riot (Valorant / LoL) ──────────────────────────────────────

  Future<void> connectRiot() async {
    state = state.copyWith(status: OAuthStatus.connecting);
    try {
      final result = await _detection.connectRiotAccount();
      if (result == null) {
        // User cancelled
        state = state.copyWith(status: OAuthStatus.idle);
        return;
      }
      await _fs.saveConnectedGame(_myUid, result.toMap());
      state = state.copyWith(
        status:        OAuthStatus.success,
        lastConnected: result.gameName,
      );
    } catch (e) {
      state = state.copyWith(
        status: OAuthStatus.error,
        error:  e.toString(),
      );
    }
  }

  // ── Steam ──────────────────────────────────────────────────────

  Future<void> connectSteam() async {
    state = state.copyWith(status: OAuthStatus.connecting);
    try {
      final result = await _detection.connectSteamAccount();
      if (result == null) {
        state = state.copyWith(status: OAuthStatus.idle);
        return;
      }
      await _fs.saveConnectedGame(_myUid, result.toMap());
      state = state.copyWith(
        status:        OAuthStatus.success,
        lastConnected: result.gameName,
      );
    } catch (e) {
      state = state.copyWith(
        status: OAuthStatus.error,
        error:  e.toString(),
      );
    }
  }

  // ── Auto-import detected games ─────────────────────────────────

  /// Saves all detected installed games to Firestore in one shot.
  /// Called after the user grants permission on the prompt.
  Future<void> importInstalledGames(List<DetectedGame> games) async {
    for (final game in games) {
      await _fs.saveConnectedGame(_myUid, game.toMap());
    }
    state = state.copyWith(
      status:        OAuthStatus.success,
      lastConnected: '${games.length} games',
    );
  }

  void reset() => state = const GameOAuthState();
}

final gameOAuthProvider =
    StateNotifierProvider<GameOAuthNotifier, GameOAuthState>((ref) {
  return GameOAuthNotifier(ref);
});