import 'package:equatable/equatable.dart';
import 'chat_model.dart';

// ── Enums ──────────────────────────────────────────────────────────────────

enum FriendFilter { all, inGame, online, idle }

enum FriendRequestDirection { incoming, outgoing }

// ── GameActivity ───────────────────────────────────────────────────────────

class GameActivity extends Equatable {
  const GameActivity({
    required this.gameName,
    required this.gameEmoji,
    this.mode,
    this.rank,
    this.durationMinutes,
  });

  final String gameName;
  final String gameEmoji;
  final String? mode;     // e.g. "Ranked", "Casual"
  final String? rank;     // e.g. "Plat II"
  final int? durationMinutes;

  String get activityLabel {
    final parts = <String>[gameName];
    if (mode != null) parts.add(mode!);
    return parts.join(' · ');
  }

  String get durationLabel {
    if (durationMinutes == null) return '';
    final h = durationMinutes! ~/ 60;
    final m = durationMinutes! % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  List<Object?> get props => [gameName, gameEmoji, mode, rank, durationMinutes];
}

// ── Friend ─────────────────────────────────────────────────────────────────

class Friend extends Equatable {
  const Friend({
    required this.id,
    required this.name,
    required this.handle,
    required this.avatarInitial,
    required this.avatarColorIndex,
    required this.status,
    this.activity,
    this.mutualFriends = 0,
    this.isPartyMember = false,
  });

  final String id;
  final String name;
  final String handle;       // e.g. "#kraken7744"
  final String avatarInitial;
  final int avatarColorIndex;
  final UserStatus status;
  final GameActivity? activity; // non-null when status == inGame
  final int mutualFriends;
  final bool isPartyMember;

  String get statusLabel {
    switch (status) {
      case UserStatus.online:
        return 'Online · In lobby';
      case UserStatus.inGame:
        return activity?.activityLabel ?? 'In game';
      case UserStatus.idle:
        return 'Idle';
      case UserStatus.offline:
        return 'Offline';
    }
  }

  Friend copyWith({bool? isPartyMember, UserStatus? status}) {
    return Friend(
      id: id,
      name: name,
      handle: handle,
      avatarInitial: avatarInitial,
      avatarColorIndex: avatarColorIndex,
      status: status ?? this.status,
      activity: activity,
      mutualFriends: mutualFriends,
      isPartyMember: isPartyMember ?? this.isPartyMember,
    );
  }

  @override
  List<Object?> get props => [
        id, name, handle, avatarInitial, avatarColorIndex,
        status, activity, mutualFriends, isPartyMember,
      ];
}

// ── FriendRequest ──────────────────────────────────────────────────────────

class FriendRequest extends Equatable {
  const FriendRequest({
    required this.id,
    required this.friend,
    required this.direction,
    required this.sentAt,
  });

  final String id;
  final Friend friend;
  final FriendRequestDirection direction;
  final DateTime sentAt;

  @override
  List<Object?> get props => [id, friend, direction, sentAt];
}

// ── Seed data ──────────────────────────────────────────────────────────────

final List<Friend> seedFriends = [
  // ── In game ──────────────────────────────────────────────────
  Friend(
    id: 'f1',
    name: 'KrakenSlayer',
    handle: '#kraken7744',
    avatarInitial: 'K',
    avatarColorIndex: 2,
    status: UserStatus.inGame,
    activity: const GameActivity(
      gameName: 'Valorant',
      gameEmoji: '🎯',
      mode: 'Ranked',
      rank: 'Plat II',
      durationMinutes: 134,
    ),
    mutualFriends: 8,
  ),
  Friend(
    id: 'f2',
    name: 'ArcticPhantom',
    handle: '#arctic_99',
    avatarInitial: 'A',
    avatarColorIndex: 0,
    status: UserStatus.inGame,
    activity: const GameActivity(
      gameName: 'Apex Legends',
      gameEmoji: '🔫',
      mode: 'Ranked',
      durationMinutes: 62,
    ),
    mutualFriends: 4,
  ),
  Friend(
    id: 'f3',
    name: 'DuskReaper',
    handle: '#dusk_gg',
    avatarInitial: 'D',
    avatarColorIndex: 3,
    status: UserStatus.inGame,
    activity: const GameActivity(
      gameName: 'League of Legends',
      gameEmoji: '⚔️',
      mode: 'Ranked',
      rank: 'Plat III',
      durationMinutes: 45,
    ),
    mutualFriends: 12,
  ),
  Friend(
    id: 'f4',
    name: 'NovaStealth',
    handle: '#nova_s',
    avatarInitial: 'N',
    avatarColorIndex: 3,
    status: UserStatus.inGame,
    activity: const GameActivity(
      gameName: 'Fortnite',
      gameEmoji: '🏗️',
      mode: 'Squads',
      durationMinutes: 28,
    ),
    mutualFriends: 3,
  ),

  // ── Online ────────────────────────────────────────────────────
  Friend(
    id: 'f5',
    name: 'MidnightRaider',
    handle: '#midnight_r',
    avatarInitial: 'M',
    avatarColorIndex: 4,
    status: UserStatus.online,
    mutualFriends: 6,
  ),
  Friend(
    id: 'f6',
    name: 'RiftWalker99',
    handle: '#riftwalk',
    avatarInitial: 'R',
    avatarColorIndex: 7,
    status: UserStatus.online,
    mutualFriends: 2,
  ),
  Friend(
    id: 'f7',
    name: 'IronVex',
    handle: '#ironvex',
    avatarInitial: 'I',
    avatarColorIndex: 6,
    status: UserStatus.online,
    mutualFriends: 9,
  ),

  // ── Idle ──────────────────────────────────────────────────────
  Friend(
    id: 'f8',
    name: 'VortexFrost',
    handle: '#vfrost',
    avatarInitial: 'V',
    avatarColorIndex: 5,
    status: UserStatus.idle,
    mutualFriends: 5,
  ),
  Friend(
    id: 'f9',
    name: 'ZeroGravity',
    handle: '#zerog',
    avatarInitial: 'Z',
    avatarColorIndex: 1,
    status: UserStatus.idle,
    mutualFriends: 1,
  ),

  // ── Offline ───────────────────────────────────────────────────
  Friend(
    id: 'f10',
    name: 'ShadowByte',
    handle: '#shadowb',
    avatarInitial: 'S',
    avatarColorIndex: 6,
    status: UserStatus.offline,
    mutualFriends: 7,
  ),
];

final List<FriendRequest> seedRequests = [
  FriendRequest(
    id: 'r1',
    friend: const Friend(
      id: 'fr1',
      name: 'GlitchHunter',
      handle: '#glitch_h',
      avatarInitial: 'G',
      avatarColorIndex: 1,
      status: UserStatus.online,
      mutualFriends: 3,
    ),
    direction: FriendRequestDirection.incoming,
    sentAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  FriendRequest(
    id: 'r2',
    friend: const Friend(
      id: 'fr2',
      name: 'PulseStrike',
      handle: '#pulse_s',
      avatarInitial: 'P',
      avatarColorIndex: 0,
      status: UserStatus.inGame,
      mutualFriends: 1,
      activity: GameActivity(
        gameName: 'Valorant',
        gameEmoji: '🎯',
      ),
    ),
    direction: FriendRequestDirection.incoming,
    sentAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];