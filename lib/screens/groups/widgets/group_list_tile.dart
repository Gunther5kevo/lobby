import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/group_model.dart';
import '../../../providers/groups_provider.dart';
import '../../../widgets/guild_avatar.dart';
import '../../../widgets/unread_badge.dart';

/// One row in the groups list.
///
/// Collapsed state: group icon, name, member/online count, recent activity,
///   channel tag pills, unread badge.
///
/// Expanded state (tapped): same header + inline channel list below.
///   Tapping a channel opens [GroupChannelScreen].
class GroupListTile extends ConsumerWidget {
  const GroupListTile({
    super.key,
    required this.group,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onChannelTap,
  });

  final Group group;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final void Function(Channel channel) onChannelTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ──────────────────────────────────────────
        GestureDetector(
          onTap: onToggleExpand,
          onLongPress: () => _showContextMenu(context, ref),
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(20, 13, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group avatar
                    GuildAvatar(
                      initial: group.emoji,
                      emoji: group.emoji,
                      colorIndex: group.avatarColorIndex,
                      size: 48,
                    ),
                    const SizedBox(width: 13),

                    // Name + stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(group.name, style: AppTextStyles.chatName),
                          const SizedBox(height: 3),
                          _MemberStats(group: group),
                        ],
                      ),
                    ),

                    // Unread badge + expand arrow
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (group.totalUnread > 0)
                          UnreadBadge(
                            count: group.totalUnread,
                            muted: group.isMuted,
                          ),
                        const SizedBox(height: 4),
                        AnimatedRotation(
                          turns: isExpanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Recent activity preview
                if (group.recentActivity != null) ...[
                  const SizedBox(height: 7),
                  Padding(
                    padding: const EdgeInsets.only(left: 61),
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '# ${group.recentActivityChannel}  ',
                            style: AppTextStyles.chatPreview.copyWith(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          TextSpan(
                            text: group.recentActivity,
                            style: AppTextStyles.chatPreview.copyWith(
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Channel tag pills (collapsed only)
                if (!isExpanded) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 61),
                    child: _ChannelTagRow(channels: group.channels),
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── Expanded channel list ───────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: isExpanded
              ? _ExpandedChannels(
                  group: group,
                  onChannelTap: onChannelTap,
                )
              : const SizedBox.shrink(),
        ),
      ],
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
      builder: (_) => _GroupContextMenu(group: group),
    );
  }
}

// ── Member count + online indicator ───────────────────────────────────────

class _MemberStats extends StatelessWidget {
  const _MemberStats({required this.group});
  final Group group;

  String _formatCount(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : n.toString();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${_formatCount(group.memberCount)} members',
          style: AppTextStyles.chatPreview.copyWith(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${_formatCount(group.onlineCount)} online',
          style: AppTextStyles.chatPreview.copyWith(
            fontSize: 12,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

// ── Channel tag pills (collapsed preview) ─────────────────────────────────

class _ChannelTagRow extends StatelessWidget {
  const _ChannelTagRow({required this.channels});
  final List<Channel> channels;

  @override
  Widget build(BuildContext context) {
    // Show max 4 text/strategy channels
    final previewChannels = channels
        .where((c) => c.type != ChannelType.voice)
        .take(4)
        .toList();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: previewChannels.map((c) {
        final hasUnread = c.unreadCount > 0;
        return Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: hasUnread ? AppColors.accentSoft : AppColors.bgElevated,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: hasUnread
                  ? AppColors.accent.withOpacity(0.25)
                  : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${c.prefix} ',
                style: TextStyle(
                  fontSize: 11,
                  color: hasUnread
                      ? AppColors.accentHover
                      : AppColors.textMuted,
                ),
              ),
              Text(
                c.name,
                style: AppTextStyles.sectionLabel.copyWith(
                  fontSize: 11,
                  letterSpacing: 0.05,
                  color: hasUnread
                      ? AppColors.accentHover
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Expanded channel rows ──────────────────────────────────────────────────

class _ExpandedChannels extends StatelessWidget {
  const _ExpandedChannels({
    required this.group,
    required this.onChannelTap,
  });
  final Group group;
  final void Function(Channel) onChannelTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          for (int i = 0; i < group.channels.length; i++) ...[
            if (i > 0)
              const Divider(height: 0, indent: 46),
            _ChannelRow(
              channel: group.channels[i],
              isActive: group.activeChannelId == group.channels[i].id,
              onTap: () => onChannelTap(group.channels[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.channel,
    required this.isActive,
    required this.onTap,
  });
  final Channel channel;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isVoice = channel.type == ChannelType.voice;

    return Material(
      color: isActive ? AppColors.accentSoft : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.accentSoft,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              // Channel type icon
              SizedBox(
                width: 22,
                child: Text(
                  channel.prefix,
                  style: TextStyle(
                    fontSize: isVoice ? 14 : 15,
                    color: isActive
                        ? AppColors.accentHover
                        : AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(width: 10),

              // Channel name + last message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name,
                      style: AppTextStyles.chatName.copyWith(
                        fontSize: 13.5,
                        color: isActive
                            ? AppColors.accentHover
                            : AppColors.textPrimary,
                        fontWeight: channel.unreadCount > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    if (channel.lastMessage != null && !isVoice) ...[
                      const SizedBox(height: 2),
                      Text(
                        channel.lastMessage!,
                        style: AppTextStyles.chatPreview.copyWith(
                          fontSize: 12,
                          color: channel.unreadCount > 0
                              ? AppColors.textSecondary
                              : AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (isVoice)
                      Text(
                        'Tap to join',
                        style: AppTextStyles.chatPreview.copyWith(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),

              // Unread badge
              if (channel.unreadCount > 0)
                UnreadBadge(count: channel.unreadCount),

              // Lock icon
              if (channel.isLocked)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.lock_outline_rounded,
                      size: 13, color: AppColors.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Group context menu ─────────────────────────────────────────────────────

class _GroupContextMenu extends ConsumerWidget {
  const _GroupContextMenu({required this.group});
  final Group group;

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
          _CtxItem(
            icon: Icons.notifications_off_outlined,
            label: group.isMuted ? 'Unmute Group' : 'Mute Group',
            onTap: () {
              ref.read(groupListProvider.notifier).toggleMute(group.id);
              Navigator.pop(context);
            },
          ),
          _CtxItem(
            icon: Icons.person_outline_rounded,
            label: 'View Members',
            onTap: () => Navigator.pop(context),
          ),
          _CtxItem(
            icon: Icons.share_outlined,
            label: 'Share Invite Link',
            onTap: () => Navigator.pop(context),
          ),
          _CtxItem(
            icon: Icons.logout_rounded,
            label: 'Leave Group',
            color: AppColors.danger,
            onTap: () {
              ref.read(groupListProvider.notifier).leaveGroup(group.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _CtxItem extends StatelessWidget {
  const _CtxItem({
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
          color: c, fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      horizontalTitleGap: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}