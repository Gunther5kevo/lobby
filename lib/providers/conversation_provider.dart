import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';

// ── Message list ───────────────────────────────────────────────────────────

final messagesProvider =
    StateNotifierProvider.family<MessagesNotifier, List<Message>, String>(
  (ref, chatId) => MessagesNotifier(),
);

class MessagesNotifier extends StateNotifier<List<Message>> {
  MessagesNotifier() : super(seedMessages);

  void sendText(String text) {
    if (text.trim().isEmpty) return;

    final msg = Message(
      id: 'm${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'me',
      timestamp: DateTime.now(),
      type: MessageType.text,
      text: text.trim(),
      status: MessageStatus.sending,
      isMine: true,
    );

    state = [...state, msg];

    // Simulate delivery after 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      state = [
        for (final m in state)
          if (m.id == msg.id)
            m.copyWith(status: MessageStatus.delivered)
          else
            m,
      ];
    });
  }

  void addReaction(String messageId, String emoji) {
    state = [
      for (final m in state)
        if (m.id == messageId)
          m.copyWith(reactions: _toggleReaction(m.reactions, emoji))
        else
          m,
    ];
  }

  void respondToGameInvite(String messageId, GameInviteStatus response) {
    state = [
      for (final m in state)
        if (m.id == messageId && m.gameInvite != null)
          m.copyWith(gameInvite: m.gameInvite!.copyWith(status: response))
        else
          m,
    ];
  }

  List<Reaction> _toggleReaction(List<Reaction> existing, String emoji) {
    final idx = existing.indexWhere((r) => r.emoji == emoji);
    if (idx == -1) {
      return [...existing, Reaction(emoji: emoji, count: 1)];
    }
    final updated = existing[idx];
    if (updated.count <= 1) {
      return [...existing]..removeAt(idx);
    }
    return [
      for (int i = 0; i < existing.length; i++)
        if (i == idx)
          Reaction(emoji: emoji, count: updated.count + 1)
        else
          existing[i],
    ];
  }
}

// ── Typing indicator ───────────────────────────────────────────────────────

final typingProvider = StateProvider<bool>((ref) => true);
// Starts as true so the UI demo shows the indicator immediately.

// ── Voice recording state ──────────────────────────────────────────────────

enum VoiceRecordState { idle, recording, locked }

final voiceRecordStateProvider =
    StateProvider<VoiceRecordState>((ref) => VoiceRecordState.idle);

final recordingDurationProvider = StateProvider<int>((ref) => 0); // seconds

// ── Input text ─────────────────────────────────────────────────────────────

final inputTextProvider = StateProvider<String>((ref) => '');

// ── Attachment sheet visibility ────────────────────────────────────────────

final attachSheetVisibleProvider = StateProvider<bool>((ref) => false);

// ── Scroll-to-bottom trigger (incremented to trigger scroll) ───────────────

final scrollToBottomProvider = StateProvider<int>((ref) => 0);