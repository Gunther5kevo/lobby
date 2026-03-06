import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import '../../providers/conversation_provider.dart';
import 'widgets/conversation_app_bar.dart';
import 'widgets/conversation_input_bar.dart';
import 'widgets/message_bubble.dart';
import 'widgets/typing_indicator.dart';

/// Full conversation screen.
///
/// Pass a [ChatPreview] when navigating to this screen:
///   Navigator.of(context).push(MaterialPageRoute(
///     builder: (_) => ConversationScreen(chat: chat),
///   ));
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({
    super.key,
    required this.chat,
  });

  final ChatPreview chat;

  @override
  ConsumerState<ConversationScreen> createState() =>
      _ConversationScreenState();
}

class _ConversationScreenState
    extends ConsumerState<ConversationScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider(widget.chat.id));
    final isTyping = ref.watch(typingProvider);

    // Scroll to bottom whenever messages change
    ref.listen(messagesProvider(widget.chat.id), (_, __) {
      _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: ConversationAppBar(
        name: widget.chat.name,
        statusText: _statusText(widget.chat.status),
        status: widget.chat.status,
        avatarInitial: widget.chat.avatarInitial,
        avatarColorIndex: widget.chat.avatarColorIndex,
        avatarEmoji: widget.chat.avatarEmoji,
        onInvite: () => _sendGameInvite(context),
        onMoreOptions: () => _showMoreOptions(context),
      ),
      body: Column(
        children: [
          // ── Message list ─────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                // Typing indicator always at the end
                if (isTyping && index == messages.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Row(
                      children: [
                        const SizedBox(width: 36), // avatar space
                        const TypingIndicator(),
                      ],
                    ),
                  );
                }

                final message = messages[index];
                final prevMessage = index > 0 ? messages[index - 1] : null;

                // Show date divider when the date changes between messages
                final showDateDivider = prevMessage == null ||
                    !_isSameDay(prevMessage.timestamp, message.timestamp);

                // Show mini avatar only on first message in a group
                final showAvatar = !message.isMine &&
                    (prevMessage == null ||
                        prevMessage.isMine ||
                        prevMessage.senderId != message.senderId);

                return Column(
                  children: [
                    if (showDateDivider)
                      _DateDivider(date: message.timestamp),
                    MessageBubble(
                      message: message,
                      chatId: widget.chat.id,
                      showAvatar: showAvatar,
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Input bar ────────────────────────────────────────
          ConversationInputBar(chatId: widget.chat.id),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

  String _statusText(UserStatus status) {
    switch (status) {
      case UserStatus.online:  return 'Online';
      case UserStatus.inGame:  return 'Playing Valorant · Plat II';
      case UserStatus.idle:    return 'Idle';
      case UserStatus.offline: return 'Last seen recently';
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _sendGameInvite(BuildContext context) {
    ref.read(messagesProvider(widget.chat.id).notifier);
    // In prod: push a game-picker bottom sheet then send an invite message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Game invite sent!'),
        backgroundColor: AppColors.bgElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
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

// ── Date divider ───────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});
  final DateTime date;

  String get _label {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return DateFormat('MMMM d, y').format(date);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
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
            child: Text(
              _label,
              style: AppTextStyles.chatTime.copyWith(fontSize: 11.5),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

// ── Conversation options sheet ─────────────────────────────────────────────

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
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
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
      title: Text(
        label,
        style: AppTextStyles.chatName.copyWith(
          color: c,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      horizontalTitleGap: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}