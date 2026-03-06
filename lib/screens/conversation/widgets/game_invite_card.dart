import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/message_model.dart';

/// In-chat game invite card.
/// Shows game name, mode, and accept/decline buttons.
/// When [invite.status] is not pending the buttons
/// collapse into a single status label.
class GameInviteCard extends StatelessWidget {
  const GameInviteCard({
    super.key,
    required this.messageId,
    required this.invite,
    required this.isMine,
    this.onAccept,
    this.onDecline,
  });

  final String messageId;
  final GameInviteData invite;
  final bool isMine;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderStrong, width: 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
            child: Row(
              children: [
                // Game icon
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1e3a5f), Color(0xFF2d5890)],
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    invite.gameEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Game Invite',
                        style: AppTextStyles.chatName.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${invite.gameName} · ${invite.mode}',
                        style: AppTextStyles.chatPreview.copyWith(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 0, indent: 0, endIndent: 0),

          // Action footer
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: _Footer(
              invite: invite,
              onAccept: onAccept,
              onDecline: onDecline,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Footer — changes based on invite status ────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({
    required this.invite,
    this.onAccept,
    this.onDecline,
  });

  final GameInviteData invite;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    switch (invite.status) {
      case GameInviteStatus.pending:
        return Row(
          children: [
            Expanded(
              child: _ActionBtn(
                label: 'Accept',
                color: AppColors.accent,
                textColor: Colors.white,
                onTap: onAccept,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _ActionBtn(
                label: 'Decline',
                color: AppColors.bgCard,
                textColor: AppColors.textMuted,
                onTap: onDecline,
              ),
            ),
          ],
        );

      case GameInviteStatus.accepted:
        return _StatusLabel(
          icon: Icons.check_circle_rounded,
          label: 'Accepted',
          color: AppColors.success,
        );

      case GameInviteStatus.declined:
        return _StatusLabel(
          icon: Icons.cancel_rounded,
          label: 'Declined',
          color: AppColors.textMuted,
        );

      case GameInviteStatus.expired:
        return _StatusLabel(
          icon: Icons.access_time_rounded,
          label: 'Invite expired',
          color: AppColors.textMuted,
        );
    }
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.textColor,
    this.onTap,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.sectionLabel.copyWith(
            color: textColor,
            fontSize: 12,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.chatPreview.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}