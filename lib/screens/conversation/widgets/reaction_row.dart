import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/message_model.dart';

/// Horizontal row of emoji reaction chips shown below a message bubble.
/// Tapping a chip calls [onReact] with the emoji.
/// The [+] chip opens the full emoji picker via [onOpenPicker].
class ReactionRow extends StatelessWidget {
  const ReactionRow({
    super.key,
    required this.reactions,
    required this.messageId,
    required this.onReact,
    this.onOpenPicker,
    this.isMine = false,
  });

  final List<Reaction> reactions;
  final String messageId;
  final void Function(String messageId, String emoji) onReact;
  final VoidCallback? onOpenPicker;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Wrap(
              spacing: 5,
              runSpacing: 4,
              alignment:
                  isMine ? WrapAlignment.end : WrapAlignment.start,
              children: [
                ...reactions.map((r) => _ReactionChip(
                      reaction: r,
                      onTap: () => onReact(messageId, r.emoji),
                    )),
                if (onOpenPicker != null)
                  _AddReactionChip(onTap: onOpenPicker!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single reaction chip ───────────────────────────────────────────────────

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.reaction, required this.onTap});

  final Reaction reaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.borderStrong, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(reaction.emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              reaction.count.toString(),
              style: AppTextStyles.chatPreview.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add reaction chip ──────────────────────────────────────────────────────

class _AddReactionChip extends StatelessWidget {
  const _AddReactionChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 26,
        width: 32,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: const Icon(
          Icons.add_rounded,
          size: 14,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}