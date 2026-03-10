import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/group_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/groups_provider.dart';
import '../../../widgets/guild_avatar.dart';
import 'channel_list.dart';

/// Full-screen channel view — Discord-style.
/// Messages stream from Firestore. Send writes back via [groupsActionProvider].
class GroupChannelScreen extends ConsumerStatefulWidget {
  const GroupChannelScreen({
    super.key,
    required this.group,
    required this.channel,
  });

  final Group   group;
  final Channel channel;

  @override
  ConsumerState<GroupChannelScreen> createState() =>
      _GroupChannelScreenState();
}

class _GroupChannelScreenState extends ConsumerState<GroupChannelScreen> {
  final _scrollCtrl  = ScrollController();
  final _inputCtrl   = TextEditingController();
  bool  _hasText     = false;
  bool  _sending     = false;

  String get _groupId   => widget.group.id;
  String get _channelId => widget.channel.id;

  @override
  void initState() {
    super.initState();
    // Mark read on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupsActionProvider.notifier)
          .markChannelRead(_groupId, _channelId);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() { _sending = true; _hasText = false; });
    _inputCtrl.clear();
    try {
      await ref.read(groupsActionProvider.notifier).sendMessage(
        groupId:   _groupId,
        channelId: _channelId,
        text:      text,
      );
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final channel = widget.channel;
    final isVoice = channel.type == ChannelType.voice;
    final key     = (groupId: _groupId, channelId: _channelId);
    final msgsAsync = ref.watch(groupMessagesProvider(key));

    // Auto-scroll when new messages arrive
    ref.listen(groupMessagesProvider(key), (_, next) {
      if (next.hasValue) _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _ChannelAppBar(group: widget.group, channel: channel),
                Expanded(
                  child: isVoice
                      ? _VoiceChannelView(channel: channel)
                      : _MessageList(
                          msgsAsync:    msgsAsync,
                          scrollCtrl:   _scrollCtrl,
                          myUid:        ref.watch(currentUidRequiredProvider),
                        ),
                ),
                if (!isVoice)
                  _InputBar(
                    channelName: channel.name,
                    isLocked:    channel.isLocked,
                    controller:  _inputCtrl,
                    hasText:     _hasText,
                    sending:     _sending,
                    onChanged:   (v) => setState(() => _hasText = v.trim().isNotEmpty),
                    onSend:      _send,
                  ),
              ],
            ),
            // Channel drawer slides over content
            ChannelListDrawer(
              group:             widget.group,
              activeChannelId:   channel.id,
              onChannelSelected: (newCh) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => GroupChannelScreen(
                      group:   widget.group,
                      channel: newCh,
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
}

// ── Message list ───────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.msgsAsync,
    required this.scrollCtrl,
    required this.myUid,
  });

  final AsyncValue<List<GroupMessage>> msgsAsync;
  final ScrollController scrollCtrl;
  final String myUid;

  @override
  Widget build(BuildContext context) {
    return msgsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
      ),
      error: (e, _) => Center(
        child: Text('Could not load messages',
            style: AppTextStyles.chatPreview.copyWith(color: AppColors.textMuted)),
      ),
      data: (msgs) {
        if (msgs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded,
                    size: 44, color: AppColors.textMuted),
                const SizedBox(height: 10),
                Text('No messages yet. Say something!',
                    style: AppTextStyles.chatPreview
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          );
        }
        return ListView.builder(
          controller:  scrollCtrl,
          physics:     const BouncingScrollPhysics(),
          padding:     const EdgeInsets.fromLTRB(16, 12, 16, 8),
          itemCount:   msgs.length,
          itemBuilder: (_, i) {
            final msg  = msgs[i];
            final prev = i > 0 ? msgs[i - 1] : null;
            final sameGroup = prev != null &&
                prev.senderUid == msg.senderUid &&
                msg.sentAt.difference(prev.sentAt).inMinutes < 5;
            return _MessageRow(
              msg:        msg,
              isMine:     msg.senderUid == myUid,
              showHeader: !sameGroup,
            );
          },
        );
      },
    );
  }
}

// ── Single message row ─────────────────────────────────────────────────────

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.msg,
    required this.isMine,
    required this.showHeader,
  });

  final GroupMessage msg;
  final bool isMine;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final name = isMine ? 'You' : msg.senderName;
    return Padding(
      padding: EdgeInsets.only(top: showHeader ? 12 : 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 38,
            child: showHeader
                ? GuildAvatar(
                    initial:    name[0].toUpperCase(),
                    colorIndex: msg.senderColorIndex,
                    size:       34,
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
                          name,
                          style: AppTextStyles.chatName.copyWith(
                            fontSize:  13.5,
                            color: isMine
                                ? AppColors.accentHover
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(_fmt(msg.sentAt), style: AppTextStyles.chatTime),
                      ],
                    ),
                  ),
                Text(
                  msg.text,
                  style: AppTextStyles.chatPreview.copyWith(
                    fontSize: 14,
                    color:    AppColors.textPrimary,
                    height:   1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:${m} ${t.hour < 12 ? "AM" : "PM"}';
  }
}

// ── Channel app bar ────────────────────────────────────────────────────────

class _ChannelAppBar extends ConsumerWidget {
  const _ChannelAppBar({required this.group, required this.channel});
  final Group   group;
  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color:  AppColors.bgSurface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.chevron_left_rounded,
                size: 28, color: AppColors.accent),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => ref.read(channelDrawerOpenProvider.notifier).state = true,
            child: GuildAvatar(
              initial:    group.emoji,
              emoji:      group.emoji,
              colorIndex: group.avatarColorIndex,
              size:       34,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => ref.read(channelDrawerOpenProvider.notifier).state = true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name,
                      style: AppTextStyles.chatPreview
                          .copyWith(fontSize: 11.5, color: AppColors.textMuted)),
                  Row(
                    children: [
                      Text(channel.prefix,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(width: 3),
                      Text(channel.name,
                          style: AppTextStyles.chatName.copyWith(fontSize: 15)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _BarBtn(icon: Icons.people_outline_rounded),
          const SizedBox(width: 8),
          _BarBtn(icon: Icons.search_rounded),
        ],
      ),
    );
  }
}

class _BarBtn extends StatelessWidget {
  const _BarBtn({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color:        AppColors.bgElevated,
          borderRadius: BorderRadius.circular(9),
          border:       Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 17, color: AppColors.textSecondary),
      );
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
            width: 72, height: 72,
            decoration: BoxDecoration(
              color:  AppColors.success.withOpacity(0.12),
              shape:  BoxShape.circle,
              border: Border.all(
                  color: AppColors.success.withOpacity(0.3), width: 2),
            ),
            child: const Icon(Icons.headset_rounded,
                color: AppColors.success, size: 34),
          ),
          const SizedBox(height: 16),
          Text('🔊 ${channel.name}',
              style: AppTextStyles.chatName.copyWith(fontSize: 17)),
          const SizedBox(height: 6),
          Text('No one is in voice right now',
              style: AppTextStyles.chatPreview),
          const SizedBox(height: 24),
          Container(
            height:  44,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              color:        AppColors.success,
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Text('Join Voice',
                style: AppTextStyles.chatName.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Input bar ──────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.channelName,
    required this.isLocked,
    required this.controller,
    required this.hasText,
    required this.sending,
    required this.onChanged,
    required this.onSend,
  });

  final String              channelName;
  final bool                isLocked;
  final TextEditingController controller;
  final bool                hasText;
  final bool                sending;
  final ValueChanged<String> onChanged;
  final VoidCallback         onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          14, 10, 14, MediaQuery.of(context).padding.bottom + 10),
      decoration: const BoxDecoration(
        color:  AppColors.bgSurface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: isLocked
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 15, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text('This channel is read-only',
                    style: AppTextStyles.chatPreview.copyWith(fontSize: 13)),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 100),
                    decoration: BoxDecoration(
                      color:        AppColors.bgInput,
                      borderRadius: BorderRadius.circular(12),
                      border:       Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: controller,
                      onChanged:  onChanged,
                      style: AppTextStyles.searchText.copyWith(fontSize: 14),
                      cursorColor: AppColors.accent,
                      cursorWidth: 1.5,
                      maxLines:    null,
                      decoration:  InputDecoration(
                        hintText:        'Message #$channelName',
                        hintStyle:       AppTextStyles.searchHint,
                        border:          InputBorder.none,
                        enabledBorder:   InputBorder.none,
                        focusedBorder:   InputBorder.none,
                        contentPadding:  const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        isDense:         true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: (hasText || sending)
                      ? GestureDetector(
                          key:   const ValueKey('send'),
                          onTap: onSend,
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color:        AppColors.accent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:      AppColors.accent.withOpacity(0.35),
                                  blurRadius: 12,
                                  offset:     const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: sending
                                ? const Padding(
                                    padding: EdgeInsets.all(11),
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 18),
                          ),
                        )
                      : Container(
                          key: const ValueKey('emoji'),
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color:        AppColors.bgElevated,
                            borderRadius: BorderRadius.circular(11),
                            border:       Border.all(color: AppColors.border),
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