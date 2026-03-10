import 'package:equatable/equatable.dart';
import '../models/friend_model.dart';

// ── Enums ──────────────────────────────────────────────────────────────────

enum PartyMemberReadyState {
  notReady,
  ready,
  captain, // party leader — always "ready" implicitly
}

enum VoiceState {
  connected,
  muted,
  deafened,
  disconnected,
}

enum PartyStatus {
  waitingForMembers, // < 2 members ready
  readyToQueue,      // all members ready
  inQueue,           // actively searching for match
  inGame,            // match found, in game
}

// ── GameOption ─────────────────────────────────────────────────────────────

class GameOption extends Equatable {
  const GameOption({
    required this.id,
    required this.name,
    required this.emoji,
    required this.modes,
    this.gradientStart,
    this.gradientEnd,
  });

  final String id;
  final String name;
  final String emoji;
  final List<String> modes;
  final int? gradientStart; // ARGB int
  final int? gradientEnd;

  @override
  List<Object?> get props => [id, name, emoji, modes];
}

// ── PartyMember ────────────────────────────────────────────────────────────

class PartyMember extends Equatable {
  const PartyMember({
    required this.friendId,
    required this.name,
    required this.handle,
    required this.avatarInitial,
    required this.avatarColorIndex,
    required this.readyState,
    required this.voiceState,
    this.rank,
  });

  final String friendId;
  final String name;
  final String handle;
  final String avatarInitial;
  final int avatarColorIndex;
  final PartyMemberReadyState readyState;
  final VoiceState voiceState;
  final String? rank;

  bool get isReady =>
      readyState == PartyMemberReadyState.ready ||
      readyState == PartyMemberReadyState.captain;

  PartyMember copyWith({
    PartyMemberReadyState? readyState,
    VoiceState? voiceState,
  }) {
    return PartyMember(
      friendId: friendId,
      name: name,
      handle: handle,
      avatarInitial: avatarInitial,
      avatarColorIndex: avatarColorIndex,
      readyState: readyState ?? this.readyState,
      voiceState: voiceState ?? this.voiceState,
      rank: rank,
    );
  }

  @override
  List<Object?> get props => [
        friendId, name, handle, avatarInitial,
        avatarColorIndex, readyState, voiceState, rank,
      ];
}

// ── Party ──────────────────────────────────────────────────────────────────

class Party extends Equatable {
  const Party({
    required this.id,
    required this.members,
    required this.selectedGame,
    required this.selectedMode,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final List<PartyMember> members;
  final GameOption selectedGame;
  final String selectedMode;
  final PartyStatus status;
  final DateTime createdAt;

  int get readyCount =>
      members.where((m) => m.isReady).length;

  bool get allReady => readyCount == members.length;

  PartyMember? get captain => members
      .where((m) => m.readyState == PartyMemberReadyState.captain)
      .firstOrNull;

  Party copyWith({
    List<PartyMember>? members,
    GameOption? selectedGame,
    String? selectedMode,
    PartyStatus? status,
  }) {
    return Party(
      id: id,
      members: members ?? this.members,
      selectedGame: selectedGame ?? this.selectedGame,
      selectedMode: selectedMode ?? this.selectedMode,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, members, selectedGame, selectedMode, status, createdAt];
}

// ── Seed game options ──────────────────────────────────────────────────────

final List<GameOption> gameOptions = [
  const GameOption(
    id: 'valorant',
    name: 'Valorant',
    emoji: '🎯',
    modes: ['Ranked', 'Unrated', 'Spike Rush', 'Deathmatch'],
    gradientStart: 0xFF1a2040,
    gradientEnd:   0xFF0e1428,
  ),
  const GameOption(
    id: 'apex',
    name: 'Apex Legends',
    emoji: '🔫',
    modes: ['Ranked', 'Pubs', 'Mixtape'],
    gradientStart: 0xFF1a2a1a,
    gradientEnd:   0xFF0e1e0e,
  ),
  const GameOption(
    id: 'lol',
    name: 'League',
    emoji: '⚔️',
    modes: ['Ranked Solo', 'Ranked Flex', 'ARAM', 'Normal'],
    gradientStart: 0xFF1a1a30,
    gradientEnd:   0xFF0e0e20,
  ),
  const GameOption(
    id: 'fortnite',
    name: 'Fortnite',
    emoji: '🏗️',
    modes: ['Squads', 'Duos', 'Solos', 'Zero Build'],
    gradientStart: 0xFF1a1630,
    gradientEnd:   0xFF12102a,
  ),
  const GameOption(
    id: 'overwatch',
    name: 'Overwatch 2',
    emoji: '🛡️',
    modes: ['Competitive', 'Quick Play', 'Arcade'],
    gradientStart: 0xFF1a1428,
    gradientEnd:   0xFF120e1e,
  ),
  const GameOption(
    id: 'cs2',
    name: 'CS2',
    emoji: '💣',
    modes: ['Premier', 'Competitive', 'Deathmatch'],
    gradientStart: 0xFF1a1e10,
    gradientEnd:   0xFF10140a,
  ),
];

// ── Factory: build a Party from selected friends ───────────────────────────

Party buildPartyFromFriends(List<Friend> friends) {
  final members = <PartyMember>[];

  // First friend becomes captain
  for (int i = 0; i < friends.length; i++) {
    final f = friends[i];
    members.add(PartyMember(
      friendId: f.id,
      name: f.name,
      handle: f.handle,
      avatarInitial: f.avatarInitial,
      avatarColorIndex: f.avatarColorIndex,
      readyState: i == 0
          ? PartyMemberReadyState.captain
          : PartyMemberReadyState.notReady,
      voiceState: VoiceState.connected,
      rank: f.activity?.rank,
    ));
  }

  // Add "you" as the actual local player (captain if no friends yet)
  final youMember = PartyMember(
    friendId: 'me',
    name: 'You',
    handle: '#you',
    avatarInitial: 'Y',
    avatarColorIndex: 7,
    readyState: members.isEmpty
        ? PartyMemberReadyState.captain
        : PartyMemberReadyState.ready,
    voiceState: VoiceState.connected,
  );

  return Party(
    id: 'party_${DateTime.now().millisecondsSinceEpoch}',
    members: [youMember, ...members],
    selectedGame: gameOptions.first,
    selectedMode: gameOptions.first.modes.first,
    status: PartyStatus.waitingForMembers,
    createdAt: DateTime.now(),
  );
}