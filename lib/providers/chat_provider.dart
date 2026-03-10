import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import 'auth_provider.dart';
import 'firestore_providers.dart';

// ── Live chat list from Firestore ──────────────────────────────────────────

final chatListProvider = StreamProvider<List<ChatPreview>>((ref) {
  final myUid   = ref.watch(currentUidRequiredProvider);
  final service = ref.watch(firestoreServiceProvider);

  return service.dmChatsStream(myUid).map(
    (rawList) => rawList
        .map((data) => ChatPreview.fromFirestore({...data, 'currentUid': myUid}))
        .toList(),
  );
});

// ── Search query ───────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

// ── Filtered + sectioned chats ─────────────────────────────────────────────

final pinnedChatsProvider = Provider<List<ChatPreview>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final chats = ref.watch(chatListProvider).valueOrNull ?? [];
  return chats
      .where((c) => c.isPinned)
      .where((c) => query.isEmpty || c.name.toLowerCase().contains(query))
      .toList();
});

final recentChatsProvider = Provider<List<ChatPreview>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final chats = ref.watch(chatListProvider).valueOrNull ?? [];
  return chats
      .where((c) => !c.isPinned)
      .where((c) => query.isEmpty || c.name.toLowerCase().contains(query))
      .toList();
});

final totalUnreadProvider = Provider<int>((ref) {
  final chats = ref.watch(chatListProvider).valueOrNull ?? [];
  return chats
      .where((c) => !c.isMuted)
      .fold(0, (sum, c) => sum + c.unreadCount);
});

// ── Local mute / pin overrides ─────────────────────────────────────────────

final _mutedChatsProvider  = StateProvider<Set<String>>((ref) => {});
final _pinnedChatsProvider = StateProvider<Set<String>>((ref) => {});

extension ChatListActions on WidgetRef {
  void toggleMute(String chatId) {
    final notifier = read(_mutedChatsProvider.notifier);
    final current  = read(_mutedChatsProvider);
    notifier.state = current.contains(chatId)
        ? (current.toSet()..remove(chatId))
        : (current.toSet()..add(chatId));
  }

  void togglePin(String chatId) {
    final notifier = read(_pinnedChatsProvider.notifier);
    final current  = read(_pinnedChatsProvider);
    notifier.state = current.contains(chatId)
        ? (current.toSet()..remove(chatId))
        : (current.toSet()..add(chatId));
  }
}

// ── Bottom nav index ───────────────────────────────────────────────────────

final navIndexProvider = StateProvider<int>((ref) => 0);