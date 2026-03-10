import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/party_model.dart';

/// Top section of the party lobby screen.
/// Shows the selected game name, party size, and a disband button.
class PartyHeader extends StatelessWidget {
  const PartyHeader({
    super.key,
    required this.party,
    required this.onDisband,
  });

  final Party party;
  final VoidCallback onDisband;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game emoji badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(party.selectedGame.gradientStart ?? 0xFF1a2040),
                  Color(party.selectedGame.gradientEnd   ?? 0xFF0e1428),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderStrong, width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              party.selectedGame.emoji,
              style: const TextStyle(fontSize: 26),
            ),
          ),

          const SizedBox(width: 14),

          // Title block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Party Lobby',
                      style: AppTextStyles.screenTitle.copyWith(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(status: party.status),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${party.selectedGame.name} · ${party.selectedMode} · '
                  '${party.members.length}/5 members',
                  style: AppTextStyles.chatPreview.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),

          // Disband button
          GestureDetector(
            onTap: onDisband,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.danger.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.exit_to_app_rounded,
                      size: 14, color: AppColors.danger),
                  const SizedBox(width: 5),
                  Text(
                    'Leave',
                    style: AppTextStyles.sectionLabel.copyWith(
                      fontSize: 12,
                      color: AppColors.danger,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status pill ────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final PartyStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PartyStatus.waitingForMembers => ('Waiting', AppColors.warning),
      PartyStatus.readyToQueue     => ('Ready', AppColors.success),
      PartyStatus.inQueue          => ('In Queue', AppColors.accent),
      PartyStatus.inGame           => ('In Game', AppColors.accent),
    };

    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.badge.copyWith(
          fontSize: 10,
          color: color,
        ),
      ),
    );
  }
}