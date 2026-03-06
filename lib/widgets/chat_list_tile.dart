import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/chat_model.dart';
import 'guild_avatar.dart';
import 'unread_badge.dart';

/// One row in the chat list.
///
/// Shows:
///  • Avatar with status dot
///  • Contact / group name
///  • Last message preview (with icon prefix for special types)
///  • Relative timestamp
///  • Unread badge (standard or muted)
///
/// Tapping the tile highlights it and calls [onTap].
/// Long-pressing calls [onLongPress] for a context menu.
class ChatListTile extends StatelessWidget {
  const ChatListTile({
    super.key,
    required this.chat,
    this.isActive = false,
    this.onTap,
    this.onLongPress,
  });

  final ChatPreview chat;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        splashColor: AppColors.accentSoft,
        highlightColor: AppColors.accentSoft.withOpacity(0.5),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          color: isActive
              ? AppColors.accentSoft
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(
            children: [
              // ── Avatar ──────────────────────────────────────
              GuildAvatar(
                initial: chat.avatarInitial,
                colorIndex: chat.avatarColorIndex,
                emoji: chat.avatarEmoji,
                size: 50,
                status: chat.status,
                dotBorderColor: isActive
                    ? const Color(0xFF0D1420) // approximate accentSoft bg
                    : AppColors.bgBase,
              ),

              const SizedBox(width: 13),

              // ── Text block ───────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.name,
                      style: AppTextStyles.chatName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    _PreviewText(chat: chat),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ── Right meta (time + badge) ────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTimestamp(chat.timestamp),
                    style: AppTextStyles.chatTime,
                  ),
                  const SizedBox(height: 5),
                  UnreadBadge(
                    count: chat.unreadCount,
                    muted: chat.isMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('d MMM').format(dt);
  }
}

// ── Preview text with type-aware prefix icon ──────────────────────────────

class _PreviewText extends StatelessWidget {
  const _PreviewText({required this.chat});
  final ChatPreview chat;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.chatPreview;

    switch (chat.lastMessageType) {
      case MessagePreviewType.voiceMessage:
        return Row(
          children: [
            const Icon(Icons.mic_rounded,
                size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(chat.lastMessage,
                  style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        );

      case MessagePreviewType.screenshot:
        return Row(
          children: [
            const Icon(Icons.image_outlined,
                size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(chat.lastMessage,
                  style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        );

      case MessagePreviewType.gameInvite:
        return Row(
          children: [
            const Icon(Icons.sports_esports_outlined,
                size: 13, color: AppColors.accent),
            const SizedBox(width: 4),
            Flexible(
              child: Text(chat.lastMessage,
                  style: style.copyWith(color: AppColors.accent),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        );

      case MessagePreviewType.activity:
        return Text(
          chat.lastMessage,
          style: style.copyWith(color: AppColors.textMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );

      case MessagePreviewType.text:
        return Text(
          chat.lastMessage,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
    }
  }
}