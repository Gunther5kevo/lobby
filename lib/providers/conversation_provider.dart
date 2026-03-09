import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import 'auth_provider.dart';
import 'rtdb_providers.dart';

// ── Live DM message list ───────────────────────────────────────────────────
// Converts raw RTDB maps → typed [Message] objects.
// The family key is chatId (deterministic: sorted uids joined by '_').

final messagesProvider =
    StreamProvider.family<List<Message>, String>((ref, chatId) {
  final myUid   = ref.watch(currentUidRequiredProvider);
  final service = ref.watch(rtdbServiceProvider);

  // Stream directly from RTDB and map each raw map → typed Message.
  // No nested AsyncValue — just a plain stream transform.
  return service.dmMessagesStream(chatId).map(
    (rawList) => rawList.map((m) => Message.fromRtdb(m, myUid)).toList(),
  );
});

// ── Typing indicator ───────────────────────────────────────────────────────
// True when at least one other person is typing in this chat.

final isTypingProvider = Provider.family<bool, String>((ref, chatId) {
  final users = ref.watch(typingUsersProvider(chatId));
  return users.valueOrNull?.isNotEmpty ?? false;
});

// ── Voice recording state ──────────────────────────────────────────────────

enum VoiceRecordState { idle, recording, locked }

final voiceRecordStateProvider =
    StateProvider<VoiceRecordState>((ref) => VoiceRecordState.idle);

final recordingDurationProvider = StateProvider<int>((ref) => 0); // seconds

// ── Input text ─────────────────────────────────────────────────────────────

final inputTextProvider = StateProvider<String>((ref) => '');

// ── Attachment sheet visibility ────────────────────────────────────────────

final attachSheetVisibleProvider = StateProvider<bool>((ref) => false);