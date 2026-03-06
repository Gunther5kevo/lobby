import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/profile_model.dart';
import '../../../providers/profile_provider.dart';
import '../../../widgets/section_header.dart';

/// Tabbed game stats section.
/// Shows a game selector row and a 2×2 grid of stat cards below.
class StatsSection extends ConsumerWidget {
  const StatsSection({super.key, required this.gameStats});
  final List<GameStatsEntry> gameStats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (gameStats.isEmpty) return const SizedBox.shrink();

    final activeIdx = ref.watch(activeStatsGameProvider);
    final safeIdx   = activeIdx.clamp(0, gameStats.length - 1);
    final active    = gameStats[safeIdx];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Game Stats'),

        // Game tab selector
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: gameStats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final g         = gameStats[i];
              final isActive  = i == safeIdx;
              return GestureDetector(
                onTap: () =>
                    ref.read(activeStatsGameProvider.notifier).state = i,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.accentSoft
                        : AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive
                          ? AppColors.accent.withOpacity(0.3)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(g.emoji,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        g.gameName,
                        style: AppTextStyles.sectionLabel.copyWith(
                          fontSize: 12,
                          letterSpacing: 0.05,
                          color: isActive
                              ? AppColors.accentHover
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // 2×2 stat grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: active.stats.map((stat) {
              return _StatCard(
                stat: stat,
                gradientStart: active.gradientStart,
                gradientEnd:   active.gradientEnd,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Single stat card ───────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.stat,
    this.gradientStart,
    this.gradientEnd,
  });

  final GameStat stat;
  final int? gradientStart;
  final int? gradientEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(gradientStart ?? 0xFF1a2040),
            Color(gradientEnd   ?? 0xFF0e1428),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderStrong, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            stat.value,
            style: AppTextStyles.chatName.copyWith(
              fontSize: 20,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: AppTextStyles.chatPreview.copyWith(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          if (stat.sublabel != null)
            Text(
              stat.sublabel!,
              style: AppTextStyles.chatTime.copyWith(fontSize: 10.5),
            ),
        ],
      ),
    );
  }
}