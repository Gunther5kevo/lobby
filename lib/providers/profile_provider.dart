import 'package:flutter_riverpod/flutter_riverpod.dart';

// profileActionProvider and ProfileSaveState now live in firestore_providers.dart.
// Re-export them so existing widget imports of profile_provider.dart keep working.
export 'firestore_providers.dart'
    show ProfileSaveState, ProfileActionNotifier, profileActionProvider;

// ── Settings (local — no Firestore needed) ────────────────────────────────

class SettingsState {
  const SettingsState({
    this.pushNotifications    = true,
    this.friendRequests       = true,
    this.gameInvites          = true,
    this.groupMessages        = true,
    this.soundEffects         = true,
    this.showOnlineStatus     = true,
    this.showCurrentGame      = true,
    this.allowFriendRequests  = true,
    this.compactMode          = false,
    this.showAchievements     = true,
  });

  final bool pushNotifications;
  final bool friendRequests;
  final bool gameInvites;
  final bool groupMessages;
  final bool soundEffects;
  final bool showOnlineStatus;
  final bool showCurrentGame;
  final bool allowFriendRequests;
  final bool compactMode;
  final bool showAchievements;

  SettingsState copyWith({
    bool? pushNotifications,
    bool? friendRequests,
    bool? gameInvites,
    bool? groupMessages,
    bool? soundEffects,
    bool? showOnlineStatus,
    bool? showCurrentGame,
    bool? allowFriendRequests,
    bool? compactMode,
    bool? showAchievements,
  }) =>
      SettingsState(
        pushNotifications:   pushNotifications   ?? this.pushNotifications,
        friendRequests:      friendRequests      ?? this.friendRequests,
        gameInvites:         gameInvites         ?? this.gameInvites,
        groupMessages:       groupMessages       ?? this.groupMessages,
        soundEffects:        soundEffects        ?? this.soundEffects,
        showOnlineStatus:    showOnlineStatus    ?? this.showOnlineStatus,
        showCurrentGame:     showCurrentGame     ?? this.showCurrentGame,
        allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
        compactMode:         compactMode         ?? this.compactMode,
        showAchievements:    showAchievements    ?? this.showAchievements,
      );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void toggle(String key) {
    state = switch (key) {
      'pushNotifications'   => state.copyWith(pushNotifications:   !state.pushNotifications),
      'friendRequests'      => state.copyWith(friendRequests:      !state.friendRequests),
      'gameInvites'         => state.copyWith(gameInvites:         !state.gameInvites),
      'groupMessages'       => state.copyWith(groupMessages:       !state.groupMessages),
      'soundEffects'        => state.copyWith(soundEffects:        !state.soundEffects),
      'showOnlineStatus'    => state.copyWith(showOnlineStatus:    !state.showOnlineStatus),
      'showCurrentGame'     => state.copyWith(showCurrentGame:     !state.showCurrentGame),
      'allowFriendRequests' => state.copyWith(allowFriendRequests: !state.allowFriendRequests),
      'compactMode'         => state.copyWith(compactMode:         !state.compactMode),
      'showAchievements'    => state.copyWith(showAchievements:    !state.showAchievements),
      _ => state,
    };
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

// ── Active stats tab index ─────────────────────────────────────────────────

final activeStatsGameProvider = StateProvider<int>((ref) => 0);