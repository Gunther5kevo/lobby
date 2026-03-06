import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Pill badge showing unread message count.
/// Renders nothing when [count] is 0.
///
/// [muted] variant renders in a neutral background (muted chats).
class UnreadBadge extends StatelessWidget {
  const UnreadBadge({
    super.key,
    required this.count,
    this.muted = false,
  });

  final int count;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    final label = count > 99 ? '99+' : count.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: muted ? AppColors.bgCard : AppColors.accent,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.badge.copyWith(
          color: muted ? AppColors.textMuted : Colors.white,
        ),
      ),
    );
  }
}