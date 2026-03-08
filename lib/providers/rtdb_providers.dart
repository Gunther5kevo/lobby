import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lobby/services/firestore_service.dart';
import '../services/rtdb_service.dart';
import 'auth_provider.dart';
import 'firestore_providers.dart';

// ── DM Messages ────────────────────────────────────────────────────────────

/// Live stream of messages in a DM conversation.
/// Key: chatId (deterministic from the two UIDs).
final dmMessagesProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, chatId) {
  return ref.watch(rtdbServiceProvider).dmMessagesStream(chatId);
});

// ── Group channel messages ─────────────────────────────────────────────────

/// Live stream of messages in a group channel.
/// Key: channelId.
final channelMessagesProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, channelId) {
  return ref.watch(rtdbServiceProvider).channelMessagesStream(channelId);
});

// ── Typing indicators ──────────────────────────────────────────────────────

/// List of UIDs currently typing in a chat (excludes self).
final typingUsersProvider =
    StreamProvider.family<List<String>, String>((ref, chatId) {
  final myUid = ref.watch(currentUidRequiredProvider);
  return ref.watch(rtdbServiceProvider).typingStream(chatId, myUid);
});

// ── Message send notifier ──────────────────────────────────────────────────

class MessageSendState {
  const MessageSendState({this.isSending = false, this.error});
  final bool isSending;
  final String? error;
}

class DmMessageNotifier extends StateNotifier<MessageSendState> {
  DmMessageNotifier(this._ref) : super(const MessageSendState());

  final Ref _ref;
  RtdbService      get _rtdb => _ref.read(rtdbServiceProvider);
  FirestoreService get _fs   => _ref.read(firestoreServiceProvider);

  Future<void> sendText({
    required String chatId,
    required String theirUid,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final me     = _ref.read(currentUserProvider);
    final myName = me.displayName ?? 'Player';

    state = const MessageSendState(isSending: true);
    try {
      await _rtdb.sendDmMessage(
        chatId:     chatId,
        senderUid:  me.uid,
        senderName: myName,
        text:       text.trim(),
      );

      // Update Firestore chat doc with preview + increment unread
      await _fs.createOrUpdateDmChat(
        chatId:          chatId,
        participantUids: [me.uid, theirUid],
        lastMessage:     text.trim(),
        lastSenderUid:   me.uid,
      );

      state = const MessageSendState();
    } catch (e) {
      state = MessageSendState(error: e.toString());
    }
  }

  Future<void> setTyping(String chatId, bool isTyping) async {
    final uid = _ref.read(currentUidRequiredProvider);
    await _rtdb.setTyping(chatId, uid, isTyping);
  }
}

final dmMessageNotifierProvider =
    StateNotifierProvider.family<DmMessageNotifier, MessageSendState, String>(
  (ref, chatId) => DmMessageNotifier(ref),
);

// ── Group channel message notifier ─────────────────────────────────────────

class ChannelMessageNotifier extends StateNotifier<MessageSendState> {
  ChannelMessageNotifier(this._ref, this.channelId)
      : super(const MessageSendState());

  final Ref _ref;
  final String channelId;

  RtdbService      get _rtdb => _ref.read(rtdbServiceProvider);
  FirestoreService get _fs   => _ref.read(firestoreServiceProvider);

  Future<void> sendText({
    required String groupId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final me     = _ref.read(currentUserProvider);
    final myName = me.displayName ?? 'Player';

    state = const MessageSendState(isSending: true);
    try {
      await _rtdb.sendChannelMessage(
        channelId:  channelId,
        senderUid:  me.uid,
        senderName: myName,
        text:       text.trim(),
      );

      // Update group's lastActivity in Firestore for the group list preview
      await _fs.updateGroupLastActivity(
        groupId:   groupId,
        channelId: channelId,
        preview:   text.trim(),
      );

      state = const MessageSendState();
    } catch (e) {
      state = MessageSendState(error: e.toString());
    }
  }
}

final channelMessageNotifierProvider =
    StateNotifierProvider.family<ChannelMessageNotifier, MessageSendState, String>(
  (ref, channelId) => ChannelMessageNotifier(ref, channelId),
);

// ── Party stream ───────────────────────────────────────────────────────────

/// Live stream of a party session from RTDB.
/// Returns null when the party is disbanded.
final livePartyStreamProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, partyId) {
  return ref.watch(rtdbServiceProvider).partyStream(partyId);
});

// ── Presence stream ────────────────────────────────────────────────────────

/// Whether a given user is currently online (RTDB presence).
final presenceProvider =
    StreamProvider.family<bool, String>((ref, uid) {
  return ref.watch(rtdbServiceProvider).presenceStream(uid);
});