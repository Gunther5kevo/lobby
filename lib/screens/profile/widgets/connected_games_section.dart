import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/profile_model.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/game_detection_provider.dart';
import '../../../widgets/section_header.dart';

/// Shows each connected game account with rank, username, and a connect/disconnect toggle.
class ConnectedGamesSection extends ConsumerWidget {
  const ConnectedGamesSection({super.key, required this.games});
  final List<ConnectedGame> games;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oauthState = ref.watch(gameOAuthProvider);

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
                      .read(profileActionProvider.notifier)
                      .toggleGameConnection(games[i]),
                ),
              ],
              const SizedBox(height: 10),
              // Link Another Game CTA
              GestureDetector(
                onTap: oauthState.status == OAuthStatus.connecting
                    ? null
                    : () => _showLinkSheet(context, ref),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderStrong),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      oauthState.status == OAuthStatus.connecting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: AppColors.accent, strokeWidth: 2),
                            )
                          : const Icon(Icons.add_rounded,
                              size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text(
                        oauthState.status == OAuthStatus.connecting
                            ? 'Connecting…'
                            : 'Link Another Game',
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

  void _showLinkSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LinkGameSheet(),
    );
  }
}

// ── Link game bottom sheet ─────────────────────────────────────────────────

class _LinkGameSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oauthState = ref.watch(gameOAuthProvider);
    final isLoading  = oauthState.status == OAuthStatus.connecting;

    // Show success snackbar then pop
    ref.listen<GameOAuthState>(gameOAuthProvider, (_, next) {
      if (next.status == OAuthStatus.success && next.lastConnected != null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${next.lastConnected} linked!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        ref.read(gameOAuthProvider.notifier).reset();
      }
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
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
          Text('Link a Game Account',
              style: AppTextStyles.screenTitle.copyWith(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            'Connect your accounts to show rank and stats on your profile.',
            style: AppTextStyles.chatPreview
                .copyWith(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Riot Games option
          _OAuthOption(
            emoji: '🎯',
            title: 'Riot Games',
            subtitle: 'Valorant · League of Legends',
            isLoading: isLoading,
            onTap: () => ref.read(gameOAuthProvider.notifier).connectRiot(),
          ),
          const SizedBox(height: 10),

          // Steam option
          _OAuthOption(
            emoji: '🎮',
            title: 'Steam',
            subtitle: 'PC games & playtime',
            isLoading: isLoading,
            onTap: () => ref.read(gameOAuthProvider.notifier).connectSteam(),
          ),

          if (oauthState.error != null) ...[
            const SizedBox(height: 12),
            Text(
              oauthState.error!,
              style: AppTextStyles.chatPreview
                  .copyWith(color: AppColors.danger, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _OAuthOption extends StatelessWidget {
  const _OAuthOption({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderStrong),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.chatName.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.chatPreview.copyWith(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
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