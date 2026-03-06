import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/chat_model.dart';
import '../../../widgets/guild_avatar.dart';

/// Custom app bar for the conversation screen.
/// Shows a back arrow, contact avatar + status, and two action buttons:
///   • "Invite" pill — sends a game invite
///   • Overflow menu (⋮)
class ConversationAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ConversationAppBar({
    super.key,
    required this.name,
    required this.statusText,
    required this.status,
    required this.avatarInitial,
    required this.avatarColorIndex,
    this.avatarEmoji,
    this.onBack,
    this.onInvite,
    this.onVoiceChat,
    this.onMoreOptions,
  });

  final String name;
  final String statusText;
  final UserStatus status;
  final String avatarInitial;
  final int avatarColorIndex;
  final String? avatarEmoji;

  final VoidCallback? onBack;
  final VoidCallback? onInvite;
  final VoidCallback? onVoiceChat;
  final VoidCallback? onMoreOptions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chevron_left_rounded,
                    size: 28,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
          ),

          // Avatar
          GuildAvatar(
            initial: avatarInitial,
            colorIndex: avatarColorIndex,
            emoji: avatarEmoji,
            size: 40,
            status: status,
            dotBorderColor: AppColors.bgSurface,
          ),

          const SizedBox(width: 10),

          // Name + status
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.chatName.copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusText,
                      style: AppTextStyles.chatPreview.copyWith(
                        fontSize: 12,
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Invite pill button
          _PillButton(
            icon: Icons.sports_esports_outlined,
            label: 'Invite',
            onTap: onInvite,
          ),

          const SizedBox(width: 8),

          // More options
          _IconBtn(
            icon: Icons.more_vert_rounded,
            onTap: onMoreOptions,
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (status) {
      case UserStatus.online:  return AppColors.success;
      case UserStatus.inGame:  return AppColors.accent;
      case UserStatus.idle:    return AppColors.warning;
      case UserStatus.offline: return AppColors.textMuted;
    }
  }
}

// ── Pill button ────────────────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.accentHover),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.sectionLabel.copyWith(
                color: AppColors.accentHover,
                fontSize: 12,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Icon button ────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}