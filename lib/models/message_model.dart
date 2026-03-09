import 'package:equatable/equatable.dart';
import 'chat_model.dart';

// ── Enums ──────────────────────────────────────────────────────────────────

enum MessageType {
  text,
  voiceNote,
  image,
  gameInvite,
}

enum MessageStatus {
  sending,   // single grey tick
  sent,      // single grey tick (confirmed)
  delivered, // double grey tick
  read,      // double blue tick
}

enum GameInviteStatus {
  pending,
  accepted,
  declined,
  expired,
}

// ── Sub-models ────────────────────────────────────────────────────────────

class Reaction extends Equatable {
  const Reaction({required this.emoji, required this.count});
  final String emoji;
  final int count;

  @override
  List<Object?> get props => [emoji, count];
}

class VoiceNote extends Equatable {
  const VoiceNote({
    required this.durationSeconds,
    required this.waveformData, // normalised 0.0–1.0 bar heights
    this.playedFraction = 0.0,
  });

  final int durationSeconds;
  final List<double> waveformData;
  final double playedFraction; // 0.0 = not started, 1.0 = finished

  String get durationLabel {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m > 0 ? '$m:' : ''}${s.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [durationSeconds, waveformData, playedFraction];
}

class ImageAttachment extends Equatable {
  const ImageAttachment({
    required this.label,
    required this.sublabel,
    required this.emoji,
    required this.gradientColors,
  });

  final String label;
  final String sublabel;
  final String emoji;
  final List<int> gradientColors; // [start argb, end argb]

  @override
  List<Object?> get props => [label, sublabel, emoji];
}

class GameInviteData extends Equatable {
  const GameInviteData({
    required this.gameName,
    required this.mode,
    required this.gameEmoji,
    this.status = GameInviteStatus.pending,
  });

  final String gameName;
  final String mode;
  final String gameEmoji;
  final GameInviteStatus status;

  GameInviteData copyWith({GameInviteStatus? status}) {
    return GameInviteData(
      gameName: gameName,
      mode: mode,
      gameEmoji: gameEmoji,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [gameName, mode, gameEmoji, status];
}

// ── Main Message model ─────────────────────────────────────────────────────

class Message extends Equatable {
  const Message({
    required this.id,
    required this.senderId,
    required this.timestamp,
    required this.type,
    this.text,
    this.voiceNote,
    this.image,
    this.gameInvite,
    this.reactions = const [],
    this.status = MessageStatus.read,
    this.isMine = false,
  });

  final String id;
  final String senderId;
  final DateTime timestamp;
  final MessageType type;

  // Content — only one will be non-null depending on type
  final String? text;
  final VoiceNote? voiceNote;
  final ImageAttachment? image;
  final GameInviteData? gameInvite;

  final List<Reaction> reactions;
  final MessageStatus status;
  final bool isMine;

  /// Build a [Message] from an RTDB map (as returned by [dmMessagesStream]).
  /// [myUid] is used to set [isMine] and derive reactions.
  factory Message.fromRtdb(Map<String, dynamic> m, String myUid) {
    final type = MessageType.values.firstWhere(
      (t) => t.name == (m['type'] as String? ?? 'text'),
      orElse: () => MessageType.text,
    );

    // Reactions: stored as { emoji: { uid: true } } in RTDB
    final reactionsRaw = m['reactions'] as Map? ?? {};
    final reactions = reactionsRaw.entries.map((e) {
      final voters = (e.value as Map?)?.keys.length ?? 0;
      return Reaction(emoji: e.key as String, count: voters);
    }).where((r) => r.count > 0).toList();

    return Message(
      id:        m['id']        as String? ?? '',
      senderId:  m['senderUid'] as String? ?? '',
      timestamp: m['timestamp'] is int
          ? DateTime.fromMillisecondsSinceEpoch(m['timestamp'] as int)
          : DateTime.now(),
      type:      type,
      text:      m['text'] as String?,
      reactions: reactions,
      status: MessageStatus.values.firstWhere(
        (s) => s.name == (m['status'] as String? ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      isMine: (m['senderUid'] as String? ?? '') == myUid,
    );
  }

  Message copyWith({
    List<Reaction>? reactions,
    GameInviteData? gameInvite,
    MessageStatus? status,
  }) {
    return Message(
      id: id,
      senderId: senderId,
      timestamp: timestamp,
      type: type,
      text: text,
      voiceNote: voiceNote,
      image: image,
      gameInvite: gameInvite ?? this.gameInvite,
      reactions: reactions ?? this.reactions,
      status: status ?? this.status,
      isMine: isMine,
    );
  }

  @override
  List<Object?> get props => [
        id, senderId, timestamp, type,
        text, voiceNote, image, gameInvite,
        reactions, status, isMine,
      ];
}

// ── Seed messages ──────────────────────────────────────────────────────────

final List<Message> seedMessages = [
  Message(
    id: 'm1',
    senderId: 'kraken',
    timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
    type: MessageType.text,
    text: "Yo, are you queueing for ranked tonight? Our duo hasn't played in ages 😅",
    status: MessageStatus.read,
    isMine: false,
  ),
  Message(
    id: 'm2',
    senderId: 'me',
    timestamp: DateTime.now().subtract(const Duration(minutes: 16)),
    type: MessageType.text,
    text: 'Yeah definitely! Just need to warm up a bit. My aim has been rough lately lol',
    status: MessageStatus.read,
    isMine: true,
  ),
  Message(
    id: 'm3',
    senderId: 'kraken',
    timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    type: MessageType.voiceNote,
    voiceNote: VoiceNote(
      durationSeconds: 18,
      waveformData: [
        0.3, 0.5, 0.7, 0.4, 0.9, 0.6, 0.4, 0.8,
        0.5, 0.7, 0.3, 0.6, 0.4, 0.5, 0.8, 0.6,
        0.3, 0.7, 0.5, 0.4,
      ],
      playedFraction: 0.45,
    ),
    reactions: [const Reaction(emoji: '😂', count: 2)],
    status: MessageStatus.read,
    isMine: false,
  ),
  Message(
    id: 'm4',
    senderId: 'me',
    timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
    type: MessageType.gameInvite,
    gameInvite: const GameInviteData(
      gameName: 'Valorant',
      mode: 'Ranked · 5v5',
      gameEmoji: '🎯',
      status: GameInviteStatus.accepted,
    ),
    status: MessageStatus.read,
    isMine: true,
  ),
  Message(
    id: 'm5',
    senderId: 'kraken',
    timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
    type: MessageType.image,
    image: const ImageAttachment(
      label: 'Match Result',
      sublabel: '+27 RR · Platinum II',
      emoji: '🏆',
      gradientColors: [0xFF1e2d5a, 0xFF0e1823],
    ),
    reactions: [
      Reaction(emoji: '🔥', count: 3),
      Reaction(emoji: '💪', count: 1),
    ],
    status: MessageStatus.read,
    isMine: false,
  ),
  Message(
    id: 'm6',
    senderId: 'me',
    timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    type: MessageType.text,
    text: "Let's run it back! I'm ready 🎯",
    status: MessageStatus.delivered,
    isMine: true,
  ),
];