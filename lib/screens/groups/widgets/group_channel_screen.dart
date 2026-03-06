import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/group_model.dart';
import '../../../providers/groups_provider.dart';
import '../../../widgets/guild_avatar.dart';
import '../../../widgets/unread_badge.dart';
import 'channel_list.dart';

/// Full-screen channel view inside a group.
/// Pushes onto the navigation stack from [GroupsScreen].
class GroupChannelScreen extends ConsumerStatefulWidget {
  const GroupChannelScreen({
    super.key,
    required this.group,
    required this.channel,
  });

  final Group group;
  final Channel channel;

  @override
  ConsumerState<GroupChannelScreen> createState() =>
      _GroupChannelScreenState();
}

class _GroupChannelScreenState
    extends ConsumerState<GroupChannelScreen> {
  final _scrollController = ScrollController();
  final _inputController  = TextEditingController();
  bool _hasText = false;

  // Seeded messages per channel for demo
  late final List<_ChannelMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = _generateMessages(widget.channel);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group   = widget.group;
    final channel = widget.channel;
    final isVoice = channel.type == ChannelType.voice;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // ── Main content ────────────────────────────────────
            Column(
              children: [
                _ChannelAppBar(group: group, channel: channel),
                Expanded(
                  child: isVoice
                      ? _VoiceChannelView(channel: channel)
                      : _TextChannelView(
                          messages: _messages,
                          scrollController: _scrollController,
                        ),
                ),
                if (!isVoice)
                  _ChannelInputBar(
                    groupName: group.name,
                    channelName: channel.name,
                    isLocked: channel.isLocked,
                    controller: _inputController,
                    hasText: _hasText,
                    onChanged: (v) =>
                        setState(() => _hasText = v.trim().isNotEmpty),
                    onSend: _sendMessage,
                  ),
              ],
            ),

            // ── Channel list drawer (slides over content) ───────
            ChannelListDrawer(
              group: group,
              activeChannelId: channel.id,
              onChannelSelected: (newChannel) {
                // Replace the current route with the new channel
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => GroupChannelScreen(
                      group: group,
                      channel: newChannel,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChannelMessage(
        sender: 'You',
        avatarInitial: 'Y',
        avatarColorIndex: 7,
        text: text,
        time: DateTime.now(),
        isMine: true,
      ));
      _hasText = false;
    });
    _inputController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  List<_ChannelMessage> _generateMessages(Channel ch) {
    final samples = [
      _ChannelMessage(
          sender: 'KrakenSlayer',
          avatarInitial: 'K',
          avatarColorIndex: 2,
          text: 'gg everyone, great games tonight 🔥',
          time: DateTime.now().subtract(const Duration(minutes: 12))),
      _ChannelMessage(
          sender: 'ArcticPhantom',
          avatarInitial: 'A',
          avatarColorIndex: 0,
          text: 'That last clutch was insane, how did you pull that off 😅',
          time: DateTime.now().subtract(const Duration(minutes: 10))),
      _ChannelMessage(
          sender: 'MidnightRaider',
          avatarInitial: 'M',
          avatarColorIndex: 4,
          text: 'Pure muscle memory at this point lol',
          time: DateTime.now().subtract(const Duration(minutes: 9))),
      _ChannelMessage(
          sender: 'KrakenSlayer',
          avatarInitial: 'K',
          avatarColorIndex: 2,
          text: 'Anyone down for another 5-stack tomorrow evening? Need to grind before the ranked reset',
          time: DateTime.now().subtract(const Duration(minutes: 6))),
      _ChannelMessage(
          sender: 'DuskReaper',
          avatarInitial: 'D',
          avatarColorIndex: 3,
          text: 'I\'m in, what time?',
          time: DateTime.now().subtract(const Duration(minutes: 4))),
      _ChannelMessage(
          sender: 'MidnightRaider',
          avatarInitial: 'M',
          avatarColorIndex: 4,
          text: '8pm EST works for me 👍',
          time: DateTime.now().subtract(const Duration(minutes: 3))),
    ];
    return samples;
  }
}

// ── Channel app bar ────────────────────────────────────────────────────────

class _ChannelAppBar extends ConsumerWidget {
  const _ChannelAppBar({required this.group, required this.channel});
  final Group group;
  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.chevron_left_rounded,
                size: 28, color: AppColors.accent),
          ),
          const SizedBox(width: 4),
          // Channel list toggle button
          GestureDetector(
            onTap: () => ref
                .read(channelDrawerOpenProvider.notifier)
                .state = true,
            child: GuildAvatar(
              initial: group.emoji,
              emoji: group.emoji,
              colorIndex: group.avatarColorIndex,
              size: 34,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => ref
                  .read(channelDrawerOpenProvider.notifier)
                  .state = true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: AppTextStyles.chatPreview.copyWith(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        channel.prefix,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        channel.name,
                        style: AppTextStyles.chatName.copyWith(fontSize: 15),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Members icon
          _AppBarBtn(icon: Icons.people_outline_rounded),
          const SizedBox(width: 8),
          _AppBarBtn(icon: Icons.search_rounded),
        ],
      ),
    );
  }
}

class _AppBarBtn extends StatelessWidget {
  const _AppBarBtn({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, size: 17, color: AppColors.textSecondary),
    );
  }
}

// ── Text channel message list ──────────────────────────────────────────────

class _TextChannelView extends StatelessWidget {
  const _TextChannelView({
    required this.messages,
    required this.scrollController,
  });
  final List<_ChannelMessage> messages;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];
        final prevMsg = i > 0 ? messages[i - 1] : null;
        // Group messages from same sender within 2 min
        final sameGroup = prevMsg != null &&
            prevMsg.sender == msg.sender &&
            msg.time.difference(prevMsg.time).inMinutes < 2;

        return _GroupMessageRow(
          message: msg,
          showHeader: !sameGroup,
        );
      },
    );
  }
}

// ── Voice channel placeholder ──────────────────────────────────────────────

class _VoiceChannelView extends StatelessWidget {
  const _VoiceChannelView({required this.channel});
  final Channel channel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.success.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(Icons.headset_rounded,
                color: AppColors.success, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            '🔊 ${channel.name}',
            style: AppTextStyles.chatName.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 6),
          Text(
            'No one is in voice right now',
            style: AppTextStyles.chatPreview,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Text(
                'Join Voice',
                style: AppTextStyles.chatName.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Channel input bar ──────────────────────────────────────────────────────

class _ChannelInputBar extends StatelessWidget {
  const _ChannelInputBar({
    required this.groupName,
    required this.channelName,
    required this.isLocked,
    required this.controller,
    required this.hasText,
    required this.onChanged,
    required this.onSend,
  });

  final String groupName;
  final String channelName;
  final bool isLocked;
  final TextEditingController controller;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          14, 10, 14, MediaQuery.of(context).padding.bottom + 10),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: isLocked
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 15, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  'This channel is read-only',
                  style: AppTextStyles.chatPreview.copyWith(fontSize: 13),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 100),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      style: AppTextStyles.searchText.copyWith(fontSize: 14),
                      cursorColor: AppColors.accent,
                      cursorWidth: 1.5,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Message # $channelName',
                        hintStyle: AppTextStyles.searchHint,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: hasText
                      ? GestureDetector(
                          key: const ValueKey('send'),
                          onTap: onSend,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.send_rounded,
                                color: Colors.white, size: 18),
                          ),
                        )
                      : Container(
                          key: const ValueKey('emoji'),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.bgElevated,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.emoji_emotions_outlined,
                              size: 20, color: AppColors.textMuted),
                        ),
                ),
              ],
            ),
    );
  }
}

// ── Message row ────────────────────────────────────────────────────────────

class _ChannelMessage {
  const _ChannelMessage({
    required this.sender,
    required this.avatarInitial,
    required this.avatarColorIndex,
    required this.text,
    required this.time,
    this.isMine = false,
  });
  final String sender;
  final String avatarInitial;
  final int avatarColorIndex;
  final String text;
  final DateTime time;
  final bool isMine;
}

class _GroupMessageRow extends StatelessWidget {
  const _GroupMessageRow({
    required this.message,
    required this.showHeader,
  });
  final _ChannelMessage message;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: showHeader ? 10 : 2, bottom: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar (only on first in group)
          SizedBox(
            width: 38,
            child: showHeader
                ? GuildAvatar(
                    initial: message.avatarInitial,
                    colorIndex: message.avatarColorIndex,
                    size: 34,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showHeader)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        Text(
                          message.isMine ? 'You' : message.sender,
                          style: AppTextStyles.chatName.copyWith(
                            fontSize: 13.5,
                            color: message.isMine
                                ? AppColors.accentHover
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _formatTime(message.time),
                          style: AppTextStyles.chatTime,
                        ),
                      ],
                    ),
                  ),
                Text(
                  message.text,
                  style: AppTextStyles.chatPreview.copyWith(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}