import 'package:equatable/equatable.dart';

// ── Enums ──────────────────────────────────────────────────────────────────

enum ChannelType {
  text,       // # general
  voice,      // 🔊 voice-1
  clips,      // 🎬 clips
  strategy,   // 📋 strategy
  announcements, // 📢 announcements
}

// ── Channel ────────────────────────────────────────────────────────────────

class Channel extends Equatable {
  const Channel({
    required this.id,
    required this.name,
    required this.type,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isLocked = false,
  });

  final String id;
  final String name;
  final ChannelType type;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isLocked;

  String get prefix => switch (type) {
        ChannelType.text          => '#',
        ChannelType.voice         => '🔊',
        ChannelType.clips         => '🎬',
        ChannelType.strategy      => '📋',
        ChannelType.announcements => '📢',
      };

  Channel copyWith({int? unreadCount}) => Channel(
        id: id,
        name: name,
        type: type,
        lastMessage: lastMessage,
        lastMessageTime: lastMessageTime,
        unreadCount: unreadCount ?? this.unreadCount,
        isLocked: isLocked,
      );

  @override
  List<Object?> get props =>
      [id, name, type, lastMessage, lastMessageTime, unreadCount, isLocked];
}

// ── GroupMember ────────────────────────────────────────────────────────────

class GroupMember extends Equatable {
  const GroupMember({
    required this.id,
    required this.name,
    required this.avatarInitial,
    required this.avatarColorIndex,
    this.isOnline = false,
    this.isAdmin = false,
  });

  final String id;
  final String name;
  final String avatarInitial;
  final int avatarColorIndex;
  final bool isOnline;
  final bool isAdmin;

  @override
  List<Object?> get props =>
      [id, name, avatarInitial, avatarColorIndex, isOnline, isAdmin];
}

// ── Group ──────────────────────────────────────────────────────────────────

class Group extends Equatable {
  const Group({
    required this.id,
    required this.name,
    required this.emoji,
    required this.avatarColorIndex,
    required this.channels,
    required this.memberCount,
    required this.onlineCount,
    this.description = '',
    this.unreadCount = 0,
    this.isMuted = false,
    this.activeChannelId,
    this.recentActivity,
    this.recentActivityChannel,
    this.tags = const [],
  });

  final String id;
  final String name;
  final String emoji;
  final int avatarColorIndex;
  final List<Channel> channels;
  final int memberCount;
  final int onlineCount;
  final String description;
  final int unreadCount;
  final bool isMuted;
  final String? activeChannelId;

  // For the group list tile preview
  final String? recentActivity;
  final String? recentActivityChannel;

  final List<String> tags; // e.g. ['FPS', 'Competitive', 'NA']

  Channel? get activeChannel => activeChannelId != null
      ? channels.where((c) => c.id == activeChannelId).firstOrNull
      : channels.firstOrNull;

  int get totalUnread =>
      channels.fold(0, (sum, c) => sum + c.unreadCount);

  Group copyWith({
    String? activeChannelId,
    List<Channel>? channels,
    int? unreadCount,
    bool? isMuted,
  }) =>
      Group(
        id: id,
        name: name,
        emoji: emoji,
        avatarColorIndex: avatarColorIndex,
        channels: channels ?? this.channels,
        memberCount: memberCount,
        onlineCount: onlineCount,
        description: description,
        unreadCount: unreadCount ?? this.unreadCount,
        isMuted: isMuted ?? this.isMuted,
        activeChannelId: activeChannelId ?? this.activeChannelId,
        recentActivity: recentActivity,
        recentActivityChannel: recentActivityChannel,
        tags: tags,
      );

  @override
  List<Object?> get props => [
        id, name, emoji, avatarColorIndex, channels,
        memberCount, onlineCount, description,
        unreadCount, isMuted, activeChannelId,
        recentActivity, recentActivityChannel, tags,
      ];
}

// ── Seed data ──────────────────────────────────────────────────────────────

final List<Group> seedGroups = [
  Group(
    id: 'g1',
    name: 'Shadow Squad',
    emoji: '⚔️',
    avatarColorIndex: 0,
    memberCount: 847,
    onlineCount: 312,
    description: 'Premier FPS competitive squad. All skill levels welcome.',
    unreadCount: 14,
    recentActivity: '"Anyone want to review last night\'s replay?"',
    recentActivityChannel: 'strategy',
    tags: ['FPS', 'Competitive', 'NA'],
    channels: [
      Channel(
        id: 'g1_general',
        name: 'general',
        type: ChannelType.text,
        lastMessage: 'gg everyone, great games tonight 🔥',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 3)),
        unreadCount: 5,
      ),
      Channel(
        id: 'g1_strategy',
        name: 'strategy',
        type: ChannelType.strategy,
        lastMessage: 'Anyone want to review last night\'s replay?',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 8)),
        unreadCount: 9,
      ),
      Channel(
        id: 'g1_clips',
        name: 'clips',
        type: ChannelType.clips,
        lastMessage: 'Check this ace I just posted 🤯',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
        unreadCount: 0,
      ),
      Channel(
        id: 'g1_lfp',
        name: 'looking-for-party',
        type: ChannelType.text,
        lastMessage: 'Need 2 for ranked, Diamond+',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 0,
      ),
      Channel(
        id: 'g1_voice',
        name: 'voice-1',
        type: ChannelType.voice,
        unreadCount: 0,
      ),
    ],
  ),

  Group(
    id: 'g2',
    name: 'Esports Playoffs',
    emoji: '🏆',
    avatarColorIndex: 1,
    memberCount: 2400,
    onlineCount: 1100,
    description: 'Follow live esports tournaments. Predictions, highlights, discussion.',
    unreadCount: 3,
    recentActivity: '"Stream starts in 45 minutes! Drop a 🔥"',
    recentActivityChannel: 'announcements',
    tags: ['Esports', 'Tournaments', 'Global'],
    channels: [
      Channel(
        id: 'g2_announce',
        name: 'announcements',
        type: ChannelType.announcements,
        lastMessage: 'Stream starts in 45 minutes! Drop a 🔥',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 20)),
        unreadCount: 1,
        isLocked: true,
      ),
      Channel(
        id: 'g2_general',
        name: 'general',
        type: ChannelType.text,
        lastMessage: 'Team Liquid looking strong this split',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 35)),
        unreadCount: 2,
      ),
      Channel(
        id: 'g2_predictions',
        name: 'predictions',
        type: ChannelType.text,
        lastMessage: 'I\'m calling Cloud9 all the way 🏆',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 3)),
        unreadCount: 0,
      ),
      Channel(
        id: 'g2_highlights',
        name: 'highlights',
        type: ChannelType.clips,
        lastMessage: 'Best plays from last week\'s matches',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 5)),
        unreadCount: 0,
      ),
    ],
  ),

  Group(
    id: 'g3',
    name: 'Valorant Ranked Hub',
    emoji: '🎯',
    avatarColorIndex: 2,
    memberCount: 5200,
    onlineCount: 2000,
    description: 'Rank up together. LFG, coaching, patch notes and agent tips.',
    unreadCount: 0,
    recentActivity: '"Diamond+ needed, 3 spots open in ranked queue"',
    recentActivityChannel: 'lfg',
    tags: ['Valorant', 'Ranked', 'All Regions'],
    channels: [
      Channel(
        id: 'g3_general',
        name: 'general',
        type: ChannelType.text,
        lastMessage: 'New patch dropped, Jett nerfs are rough 😭',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
        unreadCount: 0,
      ),
      Channel(
        id: 'g3_lfg',
        name: 'lfg',
        type: ChannelType.text,
        lastMessage: 'Diamond+ needed, 3 spots open in ranked queue',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 15)),
        unreadCount: 0,
      ),
      Channel(
        id: 'g3_tips',
        name: 'agent-tips',
        type: ChannelType.strategy,
        lastMessage: 'Sage wall spots on Icebox (updated for 8.0)',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 6)),
        unreadCount: 0,
      ),
      Channel(
        id: 'g3_patch',
        name: 'patch-notes',
        type: ChannelType.announcements,
        lastMessage: 'Patch 8.02 — Agent balance changes',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
        unreadCount: 0,
        isLocked: true,
      ),
    ],
  ),

  Group(
    id: 'g4',
    name: 'Casual Lobby',
    emoji: '🌟',
    avatarColorIndex: 3,
    memberCount: 128,
    onlineCount: 18,
    description: 'Just vibing. Games, memes, chill chat.',
    unreadCount: 0,
    recentActivity: '"Movie marathon after games tonight?"',
    recentActivityChannel: 'chill',
    tags: ['Casual', 'Chill', 'Mixed'],
    channels: [
      Channel(
        id: 'g4_chill',
        name: 'chill',
        type: ChannelType.text,
        lastMessage: 'Movie marathon after games tonight?',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 0,
      ),
      Channel(
        id: 'g4_memes',
        name: 'memes',
        type: ChannelType.clips,
        lastMessage: '💀💀💀',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 4)),
        unreadCount: 0,
      ),
      Channel(
        id: 'g4_offtopic',
        name: 'off-topic',
        type: ChannelType.text,
        lastMessage: 'Anyone watching the new season?',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
        unreadCount: 0,
      ),
    ],
  ),
];

// ── Browse suggestions (groups not yet joined) ─────────────────────────────

final List<Group> suggestedGroups = [
  Group(
    id: 'sg1',
    name: 'Apex Legends EU',
    emoji: '🔫',
    avatarColorIndex: 4,
    memberCount: 3100,
    onlineCount: 890,
    description: 'EU Apex community. LFG, coaching, ranked grind.',
    tags: ['Apex', 'EU', 'Ranked'],
    channels: [],
  ),
  Group(
    id: 'sg2',
    name: 'Game Clips & Highlights',
    emoji: '🎬',
    avatarColorIndex: 5,
    memberCount: 8900,
    onlineCount: 2200,
    description: 'Share your best gaming moments.',
    tags: ['Clips', 'All Games', 'Global'],
    channels: [],
  ),
  Group(
    id: 'sg3',
    name: 'Pro Scene Watchers',
    emoji: '👁️',
    avatarColorIndex: 6,
    memberCount: 14500,
    onlineCount: 4300,
    description: 'Pro match analysis, VOD reviews, predictions.',
    tags: ['Esports', 'Analysis', 'Global'],
    channels: [],
  ),
];