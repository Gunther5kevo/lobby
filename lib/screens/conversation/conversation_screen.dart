import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/conversation_provider.dart';
import '../../services/firestore_service.dart';
import 'widgets/conversation_app_bar.dart';
import 'widgets/conversation_input_bar.dart';
import 'widgets/message_bubble.dart';
import 'widgets/typing_indicator.dart';

/// Full DM conversation screen.
///
/// Navigate to this screen with:
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => ConversationScreen(
///       chat:     chatPreview,   // for display (name, avatar, status)
///       theirUid: otherUserUid,  // needed to build chatId + send messages
///     ),
///   ));
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({
    super.key,
    required this.chat,
    required this.theirUid,
  });

  final ChatPreview chat;
  final String theirUid;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _scrollController = ScrollController();
  late final String _chatId;

  @override
  void initState() {
    super.initState();
    // Deterministic chat ID — same algorithm used in FirestoreService
    final myUid = ref.read(currentUidRequiredProvider);
    final uids  = [myUid, widget.theirUid]..sort();
    _chatId = uids.join('_');

    // Mark all messages as read when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  Future<void> _markRead() async {
    final myUid = ref.read(currentUidRequiredProvider);
    try {
      await FirestoreService().markDmRead(_chatId, myUid);
    } catch (_) {}
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(_chatId));
    final isTyping      = ref.watch(isTypingProvider(_chatId));

    // Scroll to bottom on new messages
    ref.listen(messagesProvider(_chatId), (_, next) {
      if (next.hasValue) _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: ConversationAppBar(
        name:            widget.chat.name,
        statusText:      _statusText(widget.chat.status),
        status:          widget.chat.status,
        avatarInitial:   widget.chat.avatarInitial,
        avatarColorIndex: widget.chat.avatarColorIndex,
        avatarEmoji:     widget.chat.avatarEmoji,
        onInvite:        () => _sendGameInvite(context),
        onMoreOptions:   () => _showMoreOptions(context),
      ),
      body: Column(
        children: [
          // ── Message list ───────────────────────────────────────
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent, strokeWidth: 2,
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Could not load messages',
                  style: AppTextStyles.chatPreview
                      .copyWith(color: AppColors.textMuted),
                ),
              ),
              data: (messages) => _MessageList(
                messages:       messages,
                isTyping:       isTyping,
                scrollController: _scrollController,
                chatId:         _chatId,
                theirName:      widget.chat.name,
                theirInitial:   widget.chat.avatarInitial,
                theirColorIndex: widget.chat.avatarColorIndex,
              ),
            ),
          ),

          // ── Input bar ──────────────────────────────────────────
          ConversationInputBar(
            chatId:   _chatId,
            theirUid: widget.theirUid,
          ),
        ],
      ),
    );
  }

  String _statusText(UserStatus status) => switch (status) {
    UserStatus.online  => 'Online',
    UserStatus.inGame  => 'In Game',
    UserStatus.idle    => 'Idle',
    UserStatus.offline => 'Last seen recently',
  };

  void _sendGameInvite(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Game invite sent!'),
      backgroundColor: AppColors.bgElevated,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ConversationOptionsSheet(
        contactName: widget.chat.name,
      ),
    );
  }
}

// ── Message list ───────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.isTyping,
    required this.scrollController,
    required this.chatId,
    required this.theirName,
    required this.theirInitial,
    required this.theirColorIndex,
  });

  final List<Message> messages;
  final bool          isTyping;
  final ScrollController scrollController;
  final String chatId;
  final String theirName;
  final String theirInitial;
  final int    theirColorIndex;

  @override
  Widget build(BuildContext context) {
    final itemCount = messages.length + (isTyping ? 1 : 0);

    if (itemCount == 0) {
      return Center(
        child: Text(
          'No messages yet.\nSay hello! 👋',
          textAlign: TextAlign.center,
          style: AppTextStyles.chatPreview
              .copyWith(color: AppColors.textMuted, height: 1.6),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Typing indicator pinned at end
        if (isTyping && index == messages.length) {
          return const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 4),
            child: Row(
              children: [
                SizedBox(width: 36),
                TypingIndicator(),
              ],
            ),
          );
        }

        final message  = messages[index];
        final prev     = index > 0 ? messages[index - 1] : null;

        final showDateDivider = prev == null ||
            !_isSameDay(prev.timestamp, message.timestamp);

        final showAvatar = !message.isMine &&
            (prev == null || prev.isMine || prev.senderId != message.senderId);

        return Column(
          children: [
            if (showDateDivider) _DateDivider(date: message.timestamp),
            MessageBubble(
              message:        message,
              chatId:         chatId,
              showAvatar:     showAvatar,
              theirInitial:   theirInitial,
              theirColorIndex: theirColorIndex,
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Date divider ───────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});
  final DateTime date;

  String get _label {
    final now = DateTime.now();
    if (_same(date, now)) return 'Today';
    if (_same(date, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    return DateFormat('MMMM d, y').format(date);
  }

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(_label,
                style: AppTextStyles.chatTime.copyWith(fontSize: 11.5)),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

// ── Options sheet ──────────────────────────────────────────────────────────

class _ConversationOptionsSheet extends StatelessWidget {
  const _ConversationOptionsSheet({required this.contactName});
  final String contactName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          0, 12, 0, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _OptionTile(
            icon: Icons.person_outline_rounded,
            label: 'View Profile',
            onTap: () => Navigator.pop(context),
          ),
          _OptionTile(
            icon: Icons.notifications_off_outlined,
            label: 'Mute Notifications',
            onTap: () => Navigator.pop(context),
          ),
          _OptionTile(
            icon: Icons.search_rounded,
            label: 'Search in Conversation',
            onTap: () => Navigator.pop(context),
          ),
          _OptionTile(
            icon: Icons.block_rounded,
            label: 'Block $contactName',
            color: AppColors.danger,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label,
          style: AppTextStyles.chatName
              .copyWith(color: c, fontWeight: FontWeight.w500)),
      onTap: onTap,
      horizontalTitleGap: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}