import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/party_model.dart';
import '../../../providers/party_provider.dart';
import '../../../widgets/guild_avatar.dart';
import '../../../models/chat_model.dart';

/// Card for a single party member.
/// Layout: avatar (with voice indicator) | name + handle + rank | ready badge
///
/// Tapping your own card toggles your ready state.
/// Other members show their ready state as read-only (in a real app
/// their state would update via websocket).
class PartyMemberCard extends ConsumerWidget {
  const PartyMemberCard({
    super.key,
    required this.member,
    this.isMe = false,
  });

  final PartyMember member;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: isMe
          ? () {
              HapticFeedback.selectionClick();
              ref.read(activePartyProvider.notifier).setMyReady(true);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: member.isReady
              ? AppColors.success.withOpacity(0.06)
              : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: member.isReady
                ? AppColors.success.withOpacity(0.2)
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar + voice ring
            _AvatarWithVoice(member: member),

            const SizedBox(width: 13),

            // Name block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isMe ? 'You' : member.name,
                          style: AppTextStyles.chatName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (member.readyState == PartyMemberReadyState.captain) ...[
                        const SizedBox(width: 6),
                        _CaptainBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        member.handle,
                        style: AppTextStyles.chatPreview.copyWith(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (member.rank != null) ...[
                        Text(
                          ' · ',
                          style: AppTextStyles.chatPreview.copyWith(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          member.rank!,
                          style: AppTextStyles.chatPreview.copyWith(
                            fontSize: 12,
                            color: AppColors.accentHover,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Ready badge / tap hint
            isMe
                ? _MyReadyToggle(readyState: member.readyState)
                : _ReadyBadge(readyState: member.readyState),
          ],
        ),
      ),
    );
  }
}

// ── Avatar with coloured voice-activity ring ───────────────────────────────

class _AvatarWithVoice extends StatelessWidget {
  const _AvatarWithVoice({required this.member});
  final PartyMember member;

  Color get _ringColor {
    return switch (member.voiceState) {
      VoiceState.connected    => AppColors.success,
      VoiceState.muted        => AppColors.textMuted,
      VoiceState.deafened     => AppColors.warning,
      VoiceState.disconnected => AppColors.danger,
    };
  }

  bool get _showRing =>
      member.voiceState == VoiceState.connected ||
      member.voiceState == VoiceState.muted ||
      member.voiceState == VoiceState.deafened;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Ring border
        if (_showRing)
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _ringColor, width: 2),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(2),
          child: GuildAvatar(
            initial: member.avatarInitial,
            colorIndex: member.avatarColorIndex,
            size: 46,
            status: UserStatus.online,
            dotBorderColor: AppColors.bgElevated,
          ),
        ),
        // Muted / deafened overlay icon
        if (member.voiceState == VoiceState.muted ||
            member.voiceState == VoiceState.deafened)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bgElevated, width: 1.5),
              ),
              child: Icon(
                member.voiceState == VoiceState.muted
                    ? Icons.mic_off_rounded
                    : Icons.headset_off_rounded,
                size: 10,
                color: AppColors.warning,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Captain badge ──────────────────────────────────────────────────────────

class _CaptainBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded,
              size: 9, color: AppColors.warning),
          const SizedBox(width: 3),
          Text(
            'Captain',
            style: AppTextStyles.badge.copyWith(
              fontSize: 9,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ready badge (read-only, for other members) ─────────────────────────────

class _ReadyBadge extends StatelessWidget {
  const _ReadyBadge({required this.readyState});
  final PartyMemberReadyState readyState;

  @override
  Widget build(BuildContext context) {
    final isReady = readyState == PartyMemberReadyState.ready ||
        readyState == PartyMemberReadyState.captain;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isReady
            ? AppColors.success.withOpacity(0.12)
            : AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isReady
              ? AppColors.success.withOpacity(0.25)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReady ? Icons.check_rounded : Icons.access_time_rounded,
            size: 13,
            color: isReady ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 5),
          Text(
            isReady ? 'Ready' : 'Not Ready',
            style: AppTextStyles.sectionLabel.copyWith(
              fontSize: 11,
              letterSpacing: 0.05,
              color: isReady ? AppColors.success : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── My ready toggle (tappable) ─────────────────────────────────────────────

class _MyReadyToggle extends ConsumerWidget {
  const _MyReadyToggle({required this.readyState});
  final PartyMemberReadyState readyState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReady = readyState == PartyMemberReadyState.ready ||
        readyState == PartyMemberReadyState.captain;
    final isCaptain = readyState == PartyMemberReadyState.captain;

    return GestureDetector(
      onTap: isCaptain
          ? null
          : () {
              HapticFeedback.selectionClick();
              ref.read(activePartyProvider.notifier).toggleReady('me');
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isReady
              ? AppColors.success.withOpacity(0.12)
              : AppColors.accentSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isReady
                ? AppColors.success.withOpacity(0.25)
                : AppColors.accent.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isReady ? Icons.check_rounded : Icons.touch_app_rounded,
              size: 13,
              color: isReady ? AppColors.success : AppColors.accentHover,
            ),
            const SizedBox(width: 5),
            Text(
              isCaptain ? 'Captain' : (isReady ? 'Ready' : 'Ready Up'),
              style: AppTextStyles.sectionLabel.copyWith(
                fontSize: 11,
                letterSpacing: 0.05,
                color: isCaptain
                    ? AppColors.warning
                    : isReady
                        ? AppColors.success
                        : AppColors.accentHover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}