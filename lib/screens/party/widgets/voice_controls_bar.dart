import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/party_model.dart';
import '../../../providers/party_provider.dart';

/// Voice channel control bar.
/// Shows the current voice status and three action buttons:
///   🎤 Mute / Unmute
///   🎧 Deafen / Undeafen
///   📞 Disconnect from voice
class VoiceControlsBar extends ConsumerWidget {
  const VoiceControlsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(myVoiceStateProvider);
    final isConnected = voiceState != VoiceState.disconnected;
    final isMuted    = voiceState == VoiceState.muted;
    final isDeafened = voiceState == VoiceState.deafened;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          // Voice status indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? AppColors.success : AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isConnected ? 'Voice Connected' : 'Voice Disconnected',
                  style: AppTextStyles.chatName.copyWith(
                    fontSize: 13,
                    color: isConnected
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
                Text(
                  isConnected
                      ? isMuted
                          ? 'Microphone muted'
                          : isDeafened
                              ? 'Deafened — can\'t hear others'
                              : 'Party channel · ${_connectedCount(ref)} connected'
                      : 'Tap to join voice',
                  style: AppTextStyles.chatPreview.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _VoiceBtn(
                icon: isMuted
                    ? Icons.mic_off_rounded
                    : Icons.mic_rounded,
                isActive: !isMuted,
                activeColor: AppColors.success,
                inactiveColor: AppColors.warning,
                tooltip: isMuted ? 'Unmute' : 'Mute',
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(activePartyProvider.notifier).toggleMyMute();
                },
              ),
              const SizedBox(width: 8),
              _VoiceBtn(
                icon: isDeafened
                    ? Icons.headset_off_rounded
                    : Icons.headset_rounded,
                isActive: !isDeafened,
                activeColor: AppColors.success,
                inactiveColor: AppColors.warning,
                tooltip: isDeafened ? 'Undeafen' : 'Deafen',
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(activePartyProvider.notifier).toggleMyDeafen();
                },
              ),
              const SizedBox(width: 8),
              _VoiceBtn(
                icon: Icons.call_end_rounded,
                isActive: false,
                activeColor: AppColors.danger,
                inactiveColor: AppColors.danger,
                tooltip: 'Leave Voice',
                onTap: () => HapticFeedback.mediumImpact(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _connectedCount(WidgetRef ref) {
    return ref
            .read(activePartyProvider)
            ?.members
            .where((m) =>
                m.voiceState == VoiceState.connected ||
                m.voiceState == VoiceState.muted)
            .length ??
        0;
  }
}

// ── Single voice button ────────────────────────────────────────────────────

class _VoiceBtn extends StatelessWidget {
  const _VoiceBtn({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}