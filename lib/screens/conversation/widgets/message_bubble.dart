import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/message_model.dart';
import '../../../providers/conversation_provider.dart';
import 'voice_message_bubble.dart';
import 'game_invite_card.dart';
import 'image_message_bubble.dart';
import 'reaction_row.dart';

/// Top-level message row.
/// Handles alignment (sent left vs received right),
/// routing content to the correct sub-widget,
/// timestamp, status ticks, and reactions.
class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.chatId,
    this.showAvatar = true,
  });

  final Message message;
  final String chatId;
  final bool showAvatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMine = message.isMine;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              // Other person's avatar placeholder (maintains alignment)
              if (!isMine)
                SizedBox(
                  width: 28 + 8, // avatar width + gap
                  child: showAvatar
                      ? _MiniAvatar()
                      : const SizedBox.shrink(),
                ),

              // Content
              Flexible(child: _buildContent(ref)),

              // Sent side spacer so bubbles don't touch screen edge
              if (isMine) const SizedBox(width: 0),
            ],
          ),

          // Timestamp + status row
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isMine ? 0 : 36,
              right: 0,
            ),
            child: Row(
              mainAxisAlignment:
                  isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  DateFormat('h:mm a').format(message.timestamp),
                  style: AppTextStyles.chatTime,
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  _StatusTicks(status: message.status),
                ],
              ],
            ),
          ),

          // Reactions
          if (message.reactions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: 0,
                left: isMine ? 0 : 36,
              ),
              child: ReactionRow(
                reactions: message.reactions,
                messageId: message.id,
                isMine: isMine,
                onReact: (id, emoji) => ref
                    .read(messagesProvider(chatId).notifier)
                    .addReaction(id, emoji),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(WidgetRef ref) {
    switch (message.type) {
      case MessageType.text:
        return _TextBubble(message: message);

      case MessageType.voiceNote:
        return VoiceMessageBubble(
          voiceNote: message.voiceNote!,
          isMine: message.isMine,
        );

      case MessageType.image:
        return ImageMessageBubble(
          image: message.image!,
          isMine: message.isMine,
        );

      case MessageType.gameInvite:
        return GameInviteCard(
          messageId: message.id,
          invite: message.gameInvite!,
          isMine: message.isMine,
          onAccept: () => ref
              .read(messagesProvider(chatId).notifier)
              .respondToGameInvite(message.id, GameInviteStatus.accepted),
          onDecline: () => ref
              .read(messagesProvider(chatId).notifier)
              .respondToGameInvite(message.id, GameInviteStatus.declined),
        );
    }
  }
}

// ── Text bubble ────────────────────────────────────────────────────────────

class _TextBubble extends StatelessWidget {
  const _TextBubble({required this.message});
  final Message message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMine ? AppColors.bubbleSent : AppColors.bubbleReceived,
        borderRadius: BorderRadius.only(
          topLeft:     const Radius.circular(14),
          topRight:    const Radius.circular(14),
          bottomLeft:  Radius.circular(isMine ? 14 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 14),
        ),
        border: Border.all(
          color: isMine
              ? const Color(0x334F80FF)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Text(
        message.text ?? '',
        style: AppTextStyles.chatPreview.copyWith(
          fontSize: 14,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
      ),
    );
  }
}

// ── Mini avatar for received messages ─────────────────────────────────────

class _MiniAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A2D7A), Color(0xFF6040A0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        'K',
        style: AppTextStyles.avatarInitialSm.copyWith(fontSize: 12),
      ),
    );
  }
}

// ── Status ticks ───────────────────────────────────────────────────────────

class _StatusTicks extends StatelessWidget {
  const _StatusTicks({required this.status});
  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return const Icon(Icons.access_time_rounded,
            size: 13, color: AppColors.textMuted);
      case MessageStatus.sent:
        return const Icon(Icons.check_rounded,
            size: 13, color: AppColors.textMuted);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all_rounded,
            size: 13, color: AppColors.textMuted);
      case MessageStatus.read:
        return const Icon(Icons.done_all_rounded,
            size: 13, color: AppColors.accent);
    }
  }
}