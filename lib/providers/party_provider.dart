import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/party_model.dart';
import '../models/friend_model.dart';
import '../providers/friends_provider.dart';

// ── Active party session ───────────────────────────────────────────────────
// Null means no active party.

final activePartyProvider =
    StateNotifierProvider<PartyNotifier, Party?>((ref) {
  return PartyNotifier(ref);
});

class PartyNotifier extends StateNotifier<Party?> {
  PartyNotifier(this._ref) : super(null);

  final Ref _ref;
  Timer? _queueTimer;

  // ── Lifecycle ──────────────────────────────────────────────────

  /// Creates a new party session from the currently selected party members.
  void createParty() {
    final selectedFriends = (_ref.read(friendListProvider).valueOrNull ?? [])
        .where((f) => f.isPartyMember)
        .toList();

    state = buildPartyFromFriends(selectedFriends);
  }

  /// Creates a party from an explicit list (for direct invites).
  void createPartyFromFriends(List<Friend> friends) {
    state = buildPartyFromFriends(friends);
  }

  /// Disband: clear state, unmark all party members in friends list.
  void disband() {
    _queueTimer?.cancel();
    state = null;
    clearPartyMembers(_ref);
  }

  // ── Ready state ────────────────────────────────────────────────

  void toggleReady(String friendId) {
    if (state == null) return;
    state = state!.copyWith(
      members: [
        for (final m in state!.members)
          if (m.friendId == friendId && m.readyState != PartyMemberReadyState.captain)
            m.copyWith(
              readyState: m.readyState == PartyMemberReadyState.ready
                  ? PartyMemberReadyState.notReady
                  : PartyMemberReadyState.ready,
            )
          else
            m,
      ],
    );
    _updatePartyStatus();
  }

  void setMyReady(bool ready) => toggleReady('me');

  // ── Game / mode selection ──────────────────────────────────────

  void selectGame(GameOption game) {
    if (state == null) return;
    state = state!.copyWith(
      selectedGame: game,
      selectedMode: game.modes.first,
      // Reset ready states when game changes
      members: [
        for (final m in state!.members)
          m.copyWith(
            readyState: m.readyState == PartyMemberReadyState.captain
                ? PartyMemberReadyState.captain
                : PartyMemberReadyState.notReady,
          ),
      ],
      status: PartyStatus.waitingForMembers,
    );
  }

  void selectMode(String mode) {
    if (state == null) return;
    state = state!.copyWith(selectedMode: mode);
  }

  // ── Voice ──────────────────────────────────────────────────────

  void toggleMyMute() {
    if (state == null) return;
    state = state!.copyWith(
      members: [
        for (final m in state!.members)
          if (m.friendId == 'me')
            m.copyWith(
              voiceState: m.voiceState == VoiceState.muted
                  ? VoiceState.connected
                  : VoiceState.muted,
            )
          else
            m,
      ],
    );
  }

  void toggleMyDeafen() {
    if (state == null) return;
    state = state!.copyWith(
      members: [
        for (final m in state!.members)
          if (m.friendId == 'me')
            m.copyWith(
              voiceState: m.voiceState == VoiceState.deafened
                  ? VoiceState.connected
                  : VoiceState.deafened,
            )
          else
            m,
      ],
    );
  }

  // ── Queue ──────────────────────────────────────────────────────

  void startQueue() {
    if (state == null || !state!.allReady) return;
    state = state!.copyWith(status: PartyStatus.inQueue);

    // Simulate match found after 8 seconds
    _queueTimer = Timer(const Duration(seconds: 8), () {
      if (state != null) {
        state = state!.copyWith(status: PartyStatus.inGame);
      }
    });
  }

  void cancelQueue() {
    _queueTimer?.cancel();
    state = state?.copyWith(status: PartyStatus.readyToQueue);
  }

  // ── Internals ──────────────────────────────────────────────────

  void _updatePartyStatus() {
    if (state == null) return;
    final newStatus = state!.allReady
        ? PartyStatus.readyToQueue
        : PartyStatus.waitingForMembers;
    if (state!.status != PartyStatus.inQueue &&
        state!.status != PartyStatus.inGame) {
      state = state!.copyWith(status: newStatus);
    }
  }

  @override
  void dispose() {
    _queueTimer?.cancel();
    super.dispose();
  }
}

// ── Derived: local player (me) ─────────────────────────────────────────────

final myPartyMemberProvider = Provider<PartyMember?>((ref) {
  return ref
      .watch(activePartyProvider)
      ?.members
      .where((m) => m.friendId == 'me')
      .firstOrNull;
});

// ── Derived: voice state for local player ─────────────────────────────────

final myVoiceStateProvider = Provider<VoiceState>((ref) {
  return ref.watch(myPartyMemberProvider)?.voiceState ?? VoiceState.disconnected;
});

// ── Queue elapsed timer ────────────────────────────────────────────────────

final queueElapsedProvider =
    StateNotifierProvider<_QueueTimer, Duration>((ref) {
  return _QueueTimer(ref);
});

class _QueueTimer extends StateNotifier<Duration> {
  _QueueTimer(this._ref) : super(Duration.zero) {
    _ref.listen(activePartyProvider, (prev, next) {
      if (next?.status == PartyStatus.inQueue) {
        _start();
      } else {
        _stop();
      }
    });
  }

  final Ref _ref;
  Timer? _timer;

  void _start() {
    state = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state + const Duration(seconds: 1);
    });
  }

  void _stop() {
    _timer?.cancel();
    state = Duration.zero;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}