import 'package:equatable/equatable.dart';

// ── Enums ──────────────────────────────────────────────────────────────────

enum UserStatus {
  online,
  inGame,
  idle,
  offline;

  bool get isActive => this == online || this == inGame;
}

enum MessagePreviewType {
  text,
  voiceMessage,
  screenshot,
  gameInvite,
  activity, // e.g. "🎮 Playing Valorant"
}

// ── ChatPreview ────────────────────────────────────────────────────────────

class ChatPreview extends Equatable {
  const ChatPreview({
    required this.id,
    required this.name,
    required this.avatarInitial,
    required this.avatarColorIndex,
    required this.lastMessage,
    required this.lastMessageType,
    required this.timestamp,
    required this.status,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isPinned = false,
    this.isGroup = false,
    this.avatarEmoji, // for groups / special contacts
  });

  final String id;
  final String name;
  final String avatarInitial;  // single letter or emoji
  final int avatarColorIndex;  // index into AppColors.avatarGradients
  final String lastMessage;
  final MessagePreviewType lastMessageType;
  final DateTime timestamp;
  final UserStatus status;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;
  final bool isGroup;
  final String? avatarEmoji; // shown instead of initial when set

  @override
  List<Object?> get props => [
        id, name, avatarInitial, avatarColorIndex,
        lastMessage, lastMessageType, timestamp,
        status, unreadCount, isMuted, isPinned,
        isGroup, avatarEmoji,
      ];

  ChatPreview copyWith({
    String? lastMessage,
    MessagePreviewType? lastMessageType,
    DateTime? timestamp,
    UserStatus? status,
    int? unreadCount,
    bool? isMuted,
    bool? isPinned,
  }) {
    return ChatPreview(
      id: id,
      name: name,
      avatarInitial: avatarInitial,
      avatarColorIndex: avatarColorIndex,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      isGroup: isGroup,
      avatarEmoji: avatarEmoji,
    );
  }
}

// ── Dummy seed data ────────────────────────────────────────────────────────

final List<ChatPreview> seedChats = [
  // Pinned
  ChatPreview(
    id: 'c1',
    name: 'Shadow Squad',
    avatarInitial: '⚔️',
    avatarColorIndex: 0,
    lastMessage: 'Alex: Just grabbed the sniper, hold mid!',
    lastMessageType: MessagePreviewType.text,
    timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
    status: UserStatus.inGame,
    unreadCount: 5,
    isPinned: true,
    isGroup: true,
    avatarEmoji: '⚔️',
  ),
  ChatPreview(
    id: 'c2',
    name: 'KrakenSlayer',
    avatarInitial: 'K',
    avatarColorIndex: 2,
    lastMessage: '🎮 Playing Valorant',
    lastMessageType: MessagePreviewType.activity,
    timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    status: UserStatus.inGame,
    unreadCount: 2,
    isPinned: true,
  ),
  // Recent
  ChatPreview(
    id: 'c3',
    name: 'MidnightRaider',
    avatarInitial: 'M',
    avatarColorIndex: 4,
    lastMessage: 'That clip was insane 😤',
    lastMessageType: MessagePreviewType.text,
    timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
    status: UserStatus.online,
    unreadCount: 0,
  ),
  ChatPreview(
    id: 'c4',
    name: 'Iron Vanguard',
    avatarInitial: '🛡️',
    avatarColorIndex: 1,
    lastMessage: 'Leo: Anyone up for ranked tonight?',
    lastMessageType: MessagePreviewType.text,
    timestamp: DateTime.now().subtract(const Duration(minutes: 34)),
    status: UserStatus.online,
    unreadCount: 12,
    isMuted: true,
    isGroup: true,
    avatarEmoji: '🛡️',
  ),
  ChatPreview(
    id: 'c5',
    name: 'VortexFrost',
    avatarInitial: 'V',
    avatarColorIndex: 5,
    lastMessage: '🎤 Voice message · 0:23',
    lastMessageType: MessagePreviewType.voiceMessage,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    status: UserStatus.idle,
    unreadCount: 1,
  ),
  ChatPreview(
    id: 'c6',
    name: 'NovaStealth',
    avatarInitial: 'N',
    avatarColorIndex: 3,
    lastMessage: 'gg wp, rematch tomorrow?',
    lastMessageType: MessagePreviewType.text,
    timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    status: UserStatus.offline,
    unreadCount: 0,
  ),
  ChatPreview(
    id: 'c7',
    name: 'Esports Playoffs',
    avatarInitial: '🏆',
    avatarColorIndex: 6,
    lastMessage: 'Sam: Stream goes live in 10 min',
    lastMessageType: MessagePreviewType.text,
    timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    status: UserStatus.inGame,
    unreadCount: 0,
    isGroup: true,
    avatarEmoji: '🏆',
  ),
  ChatPreview(
    id: 'c8',
    name: 'RiftWalker99',
    avatarInitial: 'R',
    avatarColorIndex: 7,
    lastMessage: '📸 Sent a screenshot',
    lastMessageType: MessagePreviewType.screenshot,
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    status: UserStatus.online,
    unreadCount: 0,
  ),
];