import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/chat_model.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat_list_tile.dart';
import '../../widgets/guild_search_bar.dart';
import '../../widgets/section_header.dart';
import '../conversation/conversation_screen.dart';

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  String? _activeChatId;

  void _openChat(ChatPreview chat) {
    setState(() => _activeChatId = chat.id);
    // ✅ markAsRead removed — no notifier on StreamProvider.
    // Call FirestoreService directly or handle via a separate action provider.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversationScreen(
          chat:     chat,
          theirUid: chat.theirUid ?? chat.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pinned     = ref.watch(pinnedChatsProvider);
    final recent     = ref.watch(recentChatsProvider);
    final hasResults = pinned.isNotEmpty || recent.isNotEmpty;
    final query      = ref.watch(searchQueryProvider);

    // Surface loading / error states from the stream
    final chatAsync = ref.watch(chatListProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChatsHeader(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: GuildSearchBar(),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: chatAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:   (e, _) => Center(child: Text('Error: $e')),
                data:    (_) => hasResults
                    ? CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          if (pinned.isNotEmpty) ...[
                            const SliverToBoxAdapter(
                              child: SectionHeader(title: 'Pinned'),
                            ),
                            SliverList.separated(
                              itemCount: pinned.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(indent: 83, height: 0),
                              itemBuilder: (context, i) {
                                final chat = pinned[i];
                                return ChatListTile(
                                  chat:        chat,
                                  isActive:    _activeChatId == chat.id,
                                  onTap:       () => _openChat(chat),
                                  onLongPress: () =>
                                      _showContextMenu(context, chat),
                                );
                              },
                            ),
                          ],
                          if (recent.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: SectionHeader(
                                title: query.isEmpty ? 'Recent' : 'Results',
                              ),
                            ),
                            SliverList.separated(
                              itemCount: recent.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(indent: 83, height: 0),
                              itemBuilder: (context, i) {
                                final chat = recent[i];
                                return ChatListTile(
                                  chat:        chat,
                                  isActive:    _activeChatId == chat.id,
                                  onTap:       () => _openChat(chat),
                                  onLongPress: () =>
                                      _showContextMenu(context, chat),
                                );
                              },
                            ),
                          ],
                          const SliverPadding(
                            padding: EdgeInsets.only(bottom: 16),
                          ),
                        ],
                      )
                    : _EmptyState(query: query),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Now receives the full ChatPreview instead of just chatId,
  // so _ChatContextMenu doesn't need to look it up from AsyncValue.
  void _showContextMenu(BuildContext context, ChatPreview chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChatContextMenu(chat: chat),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _ChatsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: 'Guild', style: AppTextStyles.appName),
                TextSpan(
                  text: 'Chat',
                  style: AppTextStyles.appName
                      .copyWith(color: AppColors.accent),
                ),
              ],
            ),
          ),
          const Spacer(),
          _HeaderIconButton(icon: Icons.info_outline_rounded,  onTap: () {}),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _HeaderIconButton(icon: Icons.edit_outlined, onTap: () {}),
              Positioned(
                top: -2, right: -2,
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accent, shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            query.isEmpty
                ? Icons.chat_bubble_outline_rounded
                : Icons.search_off_rounded,
            size: 52, color: AppColors.textMuted,
          ),
          const SizedBox(height: 14),
          Text(
            query.isEmpty ? 'No chats yet' : 'No results for "$query"',
            style: AppTextStyles.chatName.copyWith(
              color: AppColors.textMuted, fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            query.isEmpty
                ? 'Start a conversation with a friend'
                : 'Try a different name or keyword',
            style: AppTextStyles.chatPreview,
          ),
        ],
      ),
    );
  }
}

// ── Context menu ───────────────────────────────────────────────────────────

class _ChatContextMenu extends ConsumerWidget {
  const _ChatContextMenu({required this.chat});
  final ChatPreview chat; // ✅ receives full object — no AsyncValue lookup needed

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          _ContextAction(
            icon:  Icons.done_all_rounded,
            label: 'Mark as read',
            onTap: () {
              // TODO: call firestoreService.markDmChatAsRead(chat.id)
              Navigator.pop(context);
            },
          ),
          _ContextAction(
            icon: chat.isMuted
                ? Icons.notifications_outlined
                : Icons.notifications_off_outlined,
            label: chat.isMuted ? 'Unmute' : 'Mute notifications',
            onTap: () {
              ref.toggleMute(chat.id);
              Navigator.pop(context);
            },
          ),
          _ContextAction(
            icon: chat.isPinned
                ? Icons.push_pin_outlined
                : Icons.push_pin_rounded,
            label: chat.isPinned ? 'Unpin chat' : 'Pin chat',
            onTap: () {
              ref.togglePin(chat.id);
              Navigator.pop(context);
            },
          ),
          _ContextAction(
            icon:  Icons.delete_outline_rounded,
            label: 'Delete chat',
            color: AppColors.danger,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _ContextAction extends StatelessWidget {
  const _ContextAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
  final IconData    icon;
  final String      label;
  final VoidCallback onTap;
  final Color?      color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return ListTile(
      leading:  Icon(icon, color: c, size: 22),
      title:    Text(label,
          style: AppTextStyles.chatName
              .copyWith(color: c, fontWeight: FontWeight.w500)),
      onTap:    onTap,
      horizontalTitleGap: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}