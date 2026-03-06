import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';

// ── Raw chat list (would be replaced by real repo/stream in prod) ──────────

final chatListProvider =
    StateNotifierProvider<ChatListNotifier, List<ChatPreview>>((ref) {
  return ChatListNotifier();
});

class ChatListNotifier extends StateNotifier<List<ChatPreview>> {
  ChatListNotifier() : super(seedChats);

  void markAsRead(String chatId) {
    state = [
      for (final chat in state)
        if (chat.id == chatId) chat.copyWith(unreadCount: 0) else chat,
    ];
  }

  void toggleMute(String chatId) {
    state = [
      for (final chat in state)
        if (chat.id == chatId)
          chat.copyWith(isMuted: !chat.isMuted)
        else
          chat,
    ];
  }

  void togglePin(String chatId) {
    state = [
      for (final chat in state)
        if (chat.id == chatId)
          chat.copyWith(isPinned: !chat.isPinned)
        else
          chat,
    ];
  }
}

// ── Search query ───────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

// ── Filtered + sectioned chats ────────────────────────────────────────────

/// Returns pinned chats filtered by search query
final pinnedChatsProvider = Provider<List<ChatPreview>>((ref) {
  final query  = ref.watch(searchQueryProvider).toLowerCase().trim();
  final chats  = ref.watch(chatListProvider);
  return chats
      .where((c) => c.isPinned)
      .where((c) => query.isEmpty || c.name.toLowerCase().contains(query))
      .toList();
});

/// Returns recent (non-pinned) chats filtered by search query
final recentChatsProvider = Provider<List<ChatPreview>>((ref) {
  final query  = ref.watch(searchQueryProvider).toLowerCase().trim();
  final chats  = ref.watch(chatListProvider);
  return chats
      .where((c) => !c.isPinned)
      .where((c) => query.isEmpty || c.name.toLowerCase().contains(query))
      .toList();
});

/// Total unread count for badge on nav tab
final totalUnreadProvider = Provider<int>((ref) {
  return ref
      .watch(chatListProvider)
      .where((c) => !c.isMuted)
      .fold(0, (sum, c) => sum + c.unreadCount);
});

// ── Bottom nav index ───────────────────────────────────────────────────────

final navIndexProvider = StateProvider<int>((ref) => 0);