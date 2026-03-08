import 'package:equatable/equatable.dart';
import '../models/chat_model.dart';

// ── Achievement ────────────────────────────────────────────────────────────

enum AchievementRarity { common, rare, epic, legendary }

class Achievement extends Equatable {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.rarity,
    required this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementRarity rarity;
  final DateTime unlockedAt;

  @override
  List<Object?> get props => [id, title, emoji, rarity, unlockedAt];
}

// ── Game stat ──────────────────────────────────────────────────────────────

class GameStat extends Equatable {
  const GameStat({
    required this.label,
    required this.value,
    this.sublabel,
  });

  final String label;
  final String value;
  final String? sublabel;

  @override
  List<Object?> get props => [label, value, sublabel];
}

// ── Connected game account ─────────────────────────────────────────────────

class ConnectedGame extends Equatable {
  const ConnectedGame({
    required this.id,
    required this.gameName,
    required this.emoji,
    required this.accountName,
    required this.rank,
    required this.rankEmoji,
    this.isConnected = true,
  });

  final String id;
  final String gameName;
  final String emoji;
  final String accountName;
  final String rank;
  final String rankEmoji;
  final bool isConnected;

  factory ConnectedGame.fromMap(Map<String, dynamic> map) {
    return ConnectedGame(
      id:          map['id']          as String? ?? '',
      gameName:    map['gameName']    as String? ?? '',
      emoji:       map['emoji']       as String? ?? '🎮',
      accountName: map['accountName'] as String? ?? '',
      rank:        map['rank']        as String? ?? '',
      rankEmoji:   map['rankEmoji']   as String? ?? '',
      isConnected: map['isConnected'] as bool?   ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'id':          id,
    'gameName':    gameName,
    'emoji':       emoji,
    'accountName': accountName,
    'rank':        rank,
    'rankEmoji':   rankEmoji,
    'isConnected': isConnected,
  };

  ConnectedGame copyWith({bool? isConnected}) => ConnectedGame(
    id:          id,
    gameName:    gameName,
    emoji:       emoji,
    accountName: accountName,
    rank:        rank,
    rankEmoji:   rankEmoji,
    isConnected: isConnected ?? this.isConnected,
  );

  @override
  List<Object?> get props =>
      [id, gameName, emoji, accountName, rank, rankEmoji, isConnected];
}

// ── Per-game stats ─────────────────────────────────────────────────────────

class GameStatsEntry extends Equatable {
  const GameStatsEntry({
    required this.gameName,
    required this.emoji,
    required this.stats,
    this.gradientStart,
    this.gradientEnd,
  });

  final String gameName;
  final String emoji;
  final List<GameStat> stats;
  final int? gradientStart;
  final int? gradientEnd;

  @override
  List<Object?> get props => [gameName, emoji, stats];
}

// ── Main UserProfile ───────────────────────────────────────────────────────

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.handle,
    required this.bio,
    required this.avatarInitial,
    required this.avatarColorIndex,
    required this.status,
    required this.level,
    required this.xp,
    required this.xpToNext,
    required this.guildPoints,
    required this.joinedAt,
    required this.achievements,
    required this.connectedGames,
    required this.gameStats,
    this.totalFriends = 0,
    this.totalGroups  = 0,
  });

  final String id;
  final String displayName;
  final String handle;
  final String bio;
  final String avatarInitial;
  final int    avatarColorIndex;
  final UserStatus status;

  final int level;
  final int xp;
  final int xpToNext;
  final int guildPoints;

  final DateTime             joinedAt;
  final List<Achievement>    achievements;
  final List<ConnectedGame>  connectedGames;
  final List<GameStatsEntry> gameStats;

  final int totalFriends;
  final int totalGroups;

  double get xpProgress => xpToNext > 0 ? xp / xpToNext : 0;

  factory UserProfile.fromFirestore(
    Map<String, dynamic> data, {
    List<ConnectedGame>? connectedGames,
  }) {
    final rawName    = data['displayName'] as String? ?? 'User';
    final initial    = rawName.isNotEmpty ? rawName[0].toUpperCase() : 'U';

    return UserProfile(
      id:              data['uid']           as String?  ?? '',
      displayName:     rawName,
      handle:          data['handle']        as String?  ?? '#unknown',
      bio:             data['bio']           as String?  ?? '',
      avatarInitial:   initial,
      avatarColorIndex: data['avatarColorIndex'] as int? ?? 0,
      status: UserStatus.values.firstWhere(
        (s) => s.name == (data['status'] as String? ?? ''),
        orElse: () => UserStatus.offline,
      ),
      level:        data['level']        as int? ?? 1,
      xp:           data['xp']           as int? ?? 0,
      xpToNext:     data['xpToNext']     as int? ?? 1000,
      guildPoints:  data['guildPoints']  as int? ?? 0,
      joinedAt:     (data['joinedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      achievements:   [],
      connectedGames: connectedGames ?? [],
      gameStats:      [],
      totalFriends:  data['totalFriends'] as int? ?? 0,
      totalGroups:   data['totalGroups']  as int? ?? 0,
    );
  }

  UserProfile copyWith({
    String?            displayName,
    String?            handle,
    String?            bio,
    UserStatus?        status,
    List<ConnectedGame>? connectedGames,
    int?               totalFriends,
    int?               totalGroups,
  }) =>
      UserProfile(
        id:              id,
        displayName:     displayName     ?? this.displayName,
        handle:          handle          ?? this.handle,
        bio:             bio             ?? this.bio,
        avatarInitial:   avatarInitial,
        avatarColorIndex: avatarColorIndex,
        status:          status          ?? this.status,
        level:           level,
        xp:              xp,
        xpToNext:        xpToNext,
        guildPoints:     guildPoints,
        joinedAt:        joinedAt,
        achievements:    achievements,
        connectedGames:  connectedGames  ?? this.connectedGames,
        gameStats:       gameStats,
        totalFriends:    totalFriends    ?? this.totalFriends,
        totalGroups:     totalGroups     ?? this.totalGroups,
      );

  @override
  List<Object?> get props => [
        id, displayName, handle, bio, avatarInitial, avatarColorIndex,
        status, level, xp, xpToNext, guildPoints, joinedAt,
        achievements, connectedGames, gameStats, totalFriends, totalGroups,
      ];
}

// ── Seed profile (used for UI preview / tests only) ───────────────────────

final seedProfile = UserProfile(
  id: 'me',
  displayName: 'NightWarden',
  handle: '#nightwarden_gg',
  bio: 'Competitive FPS player • Valorant Diamond II • Always grinding ranked. GGs only 🎯',
  avatarInitial: 'N',
  avatarColorIndex: 7,
  status: UserStatus.online,
  level: 38,
  xp: 7400,
  xpToNext: 10000,
  guildPoints: 2840,
  joinedAt: DateTime(2023, 4, 12),
  totalFriends: 47,
  totalGroups: 4,
  achievements: [
    Achievement(
      id: 'a1',
      title: 'First Blood',
      description: 'Won your first ranked game',
      emoji: '🩸',
      rarity: AchievementRarity.common,
      unlockedAt: DateTime(2023, 4, 15),
    ),
    Achievement(
      id: 'a2',
      title: 'Squad Leader',
      description: 'Created a party and won a match',
      emoji: '⚔️',
      rarity: AchievementRarity.rare,
      unlockedAt: DateTime(2023, 6, 2),
    ),
    Achievement(
      id: 'a3',
      title: 'Diamond Grinder',
      description: 'Reached Diamond rank in any game',
      emoji: '💎',
      rarity: AchievementRarity.epic,
      unlockedAt: DateTime(2024, 1, 18),
    ),
    Achievement(
      id: 'a4',
      title: 'Clutch King',
      description: 'Won 50 clutch rounds (1vX)',
      emoji: '👑',
      rarity: AchievementRarity.epic,
      unlockedAt: DateTime(2024, 3, 5),
    ),
    Achievement(
      id: 'a5',
      title: 'Legendary Status',
      description: 'Reached level 30',
      emoji: '🏆',
      rarity: AchievementRarity.legendary,
      unlockedAt: DateTime(2024, 8, 22),
    ),
    Achievement(
      id: 'a6',
      title: 'Social Butterfly',
      description: 'Added 25+ friends',
      emoji: '🦋',
      rarity: AchievementRarity.rare,
      unlockedAt: DateTime(2024, 9, 1),
    ),
  ],
  connectedGames: const [
    ConnectedGame(
      id: 'cg1',
      gameName: 'Valorant',
      emoji: '🎯',
      accountName: 'NightWarden#NA1',
      rank: 'Diamond II',
      rankEmoji: '💎',
    ),
    ConnectedGame(
      id: 'cg2',
      gameName: 'Apex Legends',
      emoji: '🔫',
      accountName: 'NightWarden_gg',
      rank: 'Platinum III',
      rankEmoji: '🔷',
    ),
    ConnectedGame(
      id: 'cg3',
      gameName: 'League of Legends',
      emoji: '⚔️',
      accountName: 'NightWarden',
      rank: 'Gold I',
      rankEmoji: '🥇',
    ),
  ],
  gameStats: [
    GameStatsEntry(
      gameName: 'Valorant',
      emoji: '🎯',
      gradientStart: 0xFF1a2040,
      gradientEnd:   0xFF0e1428,
      stats: const [
        GameStat(label: 'K/D Ratio',  value: '1.84', sublabel: 'Season avg'),
        GameStat(label: 'Win Rate',   value: '61%',  sublabel: '248 games'),
        GameStat(label: 'HS Rate',    value: '28%',  sublabel: 'Headshots'),
        GameStat(label: 'Best Agent', value: 'Jett', sublabel: '82 games'),
      ],
    ),
    GameStatsEntry(
      gameName: 'Apex Legends',
      emoji: '🔫',
      gradientStart: 0xFF1a2a1a,
      gradientEnd:   0xFF0e1e0e,
      stats: const [
        GameStat(label: 'K/D Ratio',   value: '2.1',   sublabel: 'Season avg'),
        GameStat(label: 'Win Rate',    value: '14%',   sublabel: '104 games'),
        GameStat(label: 'Avg Damage',  value: '1,240', sublabel: 'Per game'),
        GameStat(label: 'Top Legend',  value: 'Wraith', sublabel: '61 games'),
      ],
    ),
  ],
);