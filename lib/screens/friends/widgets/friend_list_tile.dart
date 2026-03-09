import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/chat_model.dart';
import '../../../models/friend_model.dart';
import '../../../providers/firestore_providers.dart';
import '../../../providers/friends_provider.dart';
import '../../../widgets/guild_avatar.dart';

/// One row in the friends list.
///
/// Shows:
/// • Avatar with status dot
/// • Name + gamer handle
/// • Activity status line (game name, duration for in-game friends)
/// • Message button
/// • Party toggle button (highlighted when friend is in party)
///
/// Long-press opens a context menu with more options.
class FriendListTile extends ConsumerWidget {
  const FriendListTile({
    super.key,
    required this.friend,
    this.onMessage,
  });

  final Friend friend;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onMessage,
        onLongPress: () => _showContextMenu(context, ref),
        splashColor: AppColors.accentSoft,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(
            children: [
              // Avatar
              GuildAvatar(
                initial: friend.avatarInitial,
                colorIndex: friend.avatarColorIndex,
                size: 48,
                status: friend.status,
              ),

              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name row
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            friend.name,
                            style: AppTextStyles.chatName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (friend.isPartyMember) ...[
                          const SizedBox(width: 6),
                          Container(
                            height: 18,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Party',
                              style: AppTextStyles.badge.copyWith(
                                fontSize: 9.5,
                                color: AppColors.accentHover,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 3),

                    // Activity / status line
                    _ActivityLine(friend: friend),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FriendActionBtn(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Msg',
                    onTap: onMessage,
                  ),
                  const SizedBox(width: 7),
                  _PartyBtn(friend: friend),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FriendContextMenu(friend: friend),
    );
  }
}

// ── Activity line ──────────────────────────────────────────────────────────

class _ActivityLine extends StatelessWidget {
  const _ActivityLine({required this.friend});
  final Friend friend;

  @override
  Widget build(BuildContext context) {
    final color = _dotColor;

    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),

        // Game name
        if (friend.status == UserStatus.inGame && friend.activity != null) ...[
          Text(
            friend.activity!.gameName,
            style: AppTextStyles.chatPreview.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w500,
              fontSize: 12.5,
            ),
          ),
          if (friend.activity!.mode != null) ...[
            Text(
              ' · ${friend.activity!.mode}',
              style: AppTextStyles.chatPreview.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
          if (friend.activity!.durationMinutes != null) ...[
            Text(
              ' · ${friend.activity!.durationLabel}',
              style: AppTextStyles.chatPreview.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ] else
          Text(
            friend.statusLabel,
            style: AppTextStyles.chatPreview.copyWith(
              color: color,
              fontSize: 12.5,
            ),
          ),
      ],
    );
  }

  Color get _dotColor {
    switch (friend.status) {
      case UserStatus.inGame:  return AppColors.accent;
      case UserStatus.online:  return AppColors.success;
      case UserStatus.idle:    return AppColors.warning;
      case UserStatus.offline: return AppColors.textMuted;
    }
  }
}

// ── Message button ─────────────────────────────────────────────────────────

class _FriendActionBtn extends StatelessWidget {
  const _FriendActionBtn({
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
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.sectionLabel.copyWith(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                letterSpacing: 0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Party toggle button ────────────────────────────────────────────────────

class _PartyBtn extends ConsumerWidget {
  const _PartyBtn({required this.friend});
  final Friend friend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inParty = friend.isPartyMember;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        togglePartyMember(ref, friend.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: inParty ? AppColors.accentSoft : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: inParty
                ? AppColors.accent.withOpacity(0.3)
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              inParty ? Icons.group_rounded : Icons.group_add_outlined,
              size: 13,
              color: inParty ? AppColors.accentHover : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              inParty ? 'In Party' : '+ Party',
              style: AppTextStyles.sectionLabel.copyWith(
                fontSize: 11.5,
                color: inParty
                    ? AppColors.accentHover
                    : AppColors.textSecondary,
                letterSpacing: 0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Context menu ───────────────────────────────────────────────────────────

class _FriendContextMenu extends ConsumerWidget {
  const _FriendContextMenu({required this.friend});
  final Friend friend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          _CtxAction(
            icon: Icons.person_outline_rounded,
            label: 'View Profile',
            onTap: () => Navigator.pop(context),
          ),
          _CtxAction(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Send Message',
            onTap: () => Navigator.pop(context),
          ),
          _CtxAction(
            icon: Icons.sports_esports_outlined,
            label: 'Send Game Invite',
            onTap: () => Navigator.pop(context),
          ),
          _CtxAction(
            icon: Icons.person_remove_outlined,
            label: 'Remove Friend',
            color: AppColors.danger,
            onTap: () {
              ref.read(friendsActionProvider.notifier).removeFriend(friend.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _CtxAction extends StatelessWidget {
  const _CtxAction({
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
        style: AppTextStyles.chatName.copyWith(color: c, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      horizontalTitleGap: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}