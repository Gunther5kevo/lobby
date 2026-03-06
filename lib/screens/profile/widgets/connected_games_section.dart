import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/profile_model.dart';
import '../../../providers/profile_provider.dart';
import '../../../widgets/section_header.dart';

/// Shows each connected game account with rank, username, and a connect/disconnect toggle.
class ConnectedGamesSection extends ConsumerWidget {
  const ConnectedGamesSection({super.key, required this.games});
  final List<ConnectedGame> games;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Connected Games'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              for (int i = 0; i < games.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _ConnectedGameRow(
                  game: games[i],
                  onToggle: () => ref
                      .read(profileProvider.notifier)
                      .toggleGameConnection(games[i].id),
                ),
              ],
              const SizedBox(height: 10),
              // Link new game CTA
              GestureDetector(
                onTap: () {},
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderStrong),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded,
                          size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text(
                        'Link Another Game',
                        style: AppTextStyles.chatName.copyWith(
                          fontSize: 14,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConnectedGameRow extends StatelessWidget {
  const _ConnectedGameRow({
    required this.game,
    required this.onToggle,
  });
  final ConnectedGame game;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          // Game emoji icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderStrong),
            ),
            alignment: Alignment.center,
            child: Text(game.emoji, style: const TextStyle(fontSize: 20)),
          ),

          const SizedBox(width: 12),

          // Game + account info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(game.gameName,
                        style: AppTextStyles.chatName.copyWith(fontSize: 14)),
                    const SizedBox(width: 6),
                    // Rank badge
                    Container(
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(game.rankEmoji,
                              style: const TextStyle(fontSize: 10)),
                          const SizedBox(width: 3),
                          Text(
                            game.rank,
                            style: AppTextStyles.badge.copyWith(
                              fontSize: 9.5,
                              color: AppColors.accentHover,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  game.accountName,
                  style: AppTextStyles.chatPreview.copyWith(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Connected toggle
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: game.isConnected
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: game.isConnected
                      ? AppColors.success.withOpacity(0.25)
                      : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: game.isConnected
                          ? AppColors.success
                          : AppColors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    game.isConnected ? 'Connected' : 'Disconnected',
                    style: AppTextStyles.sectionLabel.copyWith(
                      fontSize: 11,
                      letterSpacing: 0.05,
                      color: game.isConnected
                          ? AppColors.success
                          : AppColors.textMuted,
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