import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/group_model.dart';
import '../../../providers/groups_provider.dart';
import '../../../widgets/guild_avatar.dart';
import '../../../widgets/unread_badge.dart';

// ── Provider: controls whether the channel drawer is open ─────────────────

final channelDrawerOpenProvider = StateProvider<bool>((ref) => false);

/// A slide-in channel list panel used inside [GroupChannelScreen].
///
/// Wrap the screen body in a [Stack] and place this on top:
///
/// ```dart
/// Stack(
///   children: [
///     _mainContent,
///     ChannelListDrawer(
///       group: group,
///       activeChannelId: channel.id,
///       onChannelSelected: (ch) { /* navigate */ },
///     ),
///   ],
/// )
/// ```
///
/// Opening/closing is controlled by [channelDrawerOpenProvider].
/// A semi-transparent scrim behind the panel closes it on tap.
class ChannelListDrawer extends ConsumerWidget {
  const ChannelListDrawer({
    super.key,
    required this.group,
    required this.activeChannelId,
    required this.onChannelSelected,
  });

  final Group group;
  final String activeChannelId;
  final void Function(Channel channel) onChannelSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(channelDrawerOpenProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: isOpen
          ? _OpenDrawer(
              key: const ValueKey('open'),
              group: group,
              activeChannelId: activeChannelId,
              onChannelSelected: onChannelSelected,
            )
          : const SizedBox.shrink(key: ValueKey('closed')),
    );
  }
}

// ── Open drawer (scrim + panel) ────────────────────────────────────────────

class _OpenDrawer extends ConsumerWidget {
  const _OpenDrawer({
    super.key,
    required this.group,
    required this.activeChannelId,
    required this.onChannelSelected,
  });

  final Group group;
  final String activeChannelId;
  final void Function(Channel channel) onChannelSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        // Scrim — tapping closes the drawer
        GestureDetector(
          onTap: () => ref.read(channelDrawerOpenProvider.notifier).state = false,
          child: Container(
            color: Colors.black.withOpacity(0.45),
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        // Panel slides in from left
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _AlwaysCompleteAnimation(),
            curve: Curves.easeOutCubic,
          )),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _ChannelPanel(
              group: group,
              activeChannelId: activeChannelId,
              onChannelSelected: onChannelSelected,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Channel panel ──────────────────────────────────────────────────────────

class _ChannelPanel extends ConsumerWidget {
  const _ChannelPanel({
    required this.group,
    required this.activeChannelId,
    required this.onChannelSelected,
  });

  final Group group;
  final String activeChannelId;
  final void Function(Channel channel) onChannelSelected;

  // Group channels by type for cleaner sections
  List<Channel> _channelsOfType(ChannelType type) =>
      group.channels.where((c) => c.type == type).toList();

  bool get _hasVoice =>
      group.channels.any((c) => c.type == ChannelType.voice);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textChannels = group.channels
        .where((c) =>
            c.type == ChannelType.text ||
            c.type == ChannelType.strategy ||
            c.type == ChannelType.clips ||
            c.type == ChannelType.announcements)
        .toList();

    final voiceChannels =
        group.channels.where((c) => c.type == ChannelType.voice).toList();

    return Container(
      width: MediaQuery.of(context).size.width * 0.76,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Group header ───────────────────────────────────
            _PanelHeader(group: group),

            // ── Divider ────────────────────────────────────────
            const Divider(height: 0),

            // ── Channel list ───────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                children: [
                  // Text channels section
                  if (textChannels.isNotEmpty) ...[
                    _SectionLabel(label: 'Channels'),
                    ...textChannels.map((ch) => _ChannelRow(
                          channel: ch,
                          isActive: ch.id == activeChannelId,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            // Mark as read in provider
                            ref
                                .read(groupListProvider.notifier)
                                .setActiveChannel(group.id, ch.id);
                            onChannelSelected(ch);
                            // Close drawer after selection
                            ref
                                .read(channelDrawerOpenProvider.notifier)
                                .state = false;
                          },
                        )),
                  ],

                  // Voice channels section
                  if (voiceChannels.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _SectionLabel(label: 'Voice'),
                    ...voiceChannels.map((ch) => _ChannelRow(
                          channel: ch,
                          isActive: ch.id == activeChannelId,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onChannelSelected(ch);
                            ref
                                .read(channelDrawerOpenProvider.notifier)
                                .state = false;
                          },
                        )),
                  ],
                ],
              ),
            ),

            // ── Member count footer ────────────────────────────
            _PanelFooter(group: group),
          ],
        ),
      ),
    );
  }
}

// ── Panel header ───────────────────────────────────────────────────────────

class _PanelHeader extends ConsumerWidget {
  const _PanelHeader({required this.group});
  final Group group;

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : n.toString();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          GuildAvatar(
            initial: group.emoji,
            emoji: group.emoji,
            colorIndex: group.avatarColorIndex,
            size: 38,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
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
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_fmt(group.onlineCount)} online',
                      style: AppTextStyles.chatPreview.copyWith(
                        fontSize: 11.5,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '·  ${_fmt(group.memberCount)} members',
                      style: AppTextStyles.chatPreview.copyWith(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Close button
          GestureDetector(
            onTap: () =>
                ref.read(channelDrawerOpenProvider.notifier).state = false,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 15, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.sectionLabel.copyWith(
          fontSize: 10.5,
          letterSpacing: 0.8,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

// ── Single channel row ─────────────────────────────────────────────────────

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
    final isVoice  = channel.type == ChannelType.voice;
    final hasUnread = channel.unreadCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.accentSoft,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Channel type prefix
              SizedBox(
                width: 22,
                child: Text(
                  channel.prefix,
                  style: TextStyle(
                    fontSize: isVoice ? 14 : 15,
                    color: isActive
                        ? AppColors.accentHover
                        : hasUnread
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(width: 10),

              // Channel name
              Expanded(
                child: Text(
                  channel.name,
                  style: AppTextStyles.chatName.copyWith(
                    fontSize: 14,
                    fontWeight: hasUnread || isActive
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isActive
                        ? AppColors.accentHover
                        : hasUnread
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Trailing: unread badge or lock icon
              if (channel.unreadCount > 0)
                UnreadBadge(count: channel.unreadCount)
              else if (channel.isLocked)
                const Icon(Icons.lock_outline_rounded,
                    size: 13, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Panel footer ───────────────────────────────────────────────────────────

class _PanelFooter extends StatelessWidget {
  const _PanelFooter({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_outline_rounded,
              size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(
            '${group.memberCount} members  ·  ${group.onlineCount} online',
            style: AppTextStyles.chatPreview.copyWith(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper: animation controller that's always complete (for slide-in) ─────
// Used so the SlideTransition animates via AnimatedSwitcher's own controller
// rather than needing a TickerProvider here.

class _AlwaysCompleteAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  @override
  Animation<double> get parent => kAlwaysCompleteAnimation;

  @override
  double get value => 1.0; 
}