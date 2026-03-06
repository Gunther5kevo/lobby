import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/profile_model.dart';
import '../../../widgets/section_header.dart';

/// Scrollable grid of achievement badges.
/// Each badge shows emoji, title, rarity colour ring, and unlock date on tap.
class AchievementsSection extends StatelessWidget {
  const AchievementsSection({
    super.key,
    required this.achievements,
  });

  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Achievements (${achievements.length})'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, i) => _AchievementBadge(
              achievement: achievements[i],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Single achievement badge ───────────────────────────────────────────────

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({required this.achievement});
  final Achievement achievement;

  Color get _rarityColor => switch (achievement.rarity) {
        AchievementRarity.common    => AppColors.textMuted,
        AchievementRarity.rare      => const Color(0xFF4F80FF),
        AchievementRarity.epic      => const Color(0xFFA855F7),
        AchievementRarity.legendary => const Color(0xFFF59E0B),
      };

  String get _rarityLabel => switch (achievement.rarity) {
        AchievementRarity.common    => 'Common',
        AchievementRarity.rare      => 'Rare',
        AchievementRarity.epic      => 'Epic',
        AchievementRarity.legendary => 'Legendary',
      };

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.bgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                achievement.emoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),
              Text(
                achievement.title,
                style: AppTextStyles.chatName.copyWith(fontSize: 17),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Container(
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: _rarityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _rarityColor.withOpacity(0.3)),
                ),
                alignment: Alignment.center,
                child: Text(
                  _rarityLabel,
                  style: AppTextStyles.badge.copyWith(
                    fontSize: 11,
                    color: _rarityColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                achievement.description,
                style: AppTextStyles.chatPreview.copyWith(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Unlocked ${DateFormat('MMM d, y').format(achievement.unlockedAt)}',
                style: AppTextStyles.chatTime,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Close',
                    style: AppTextStyles.chatName.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _rarityColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glow behind emoji
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _rarityColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                achievement.emoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                achievement.title,
                style: AppTextStyles.chatPreview.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 16,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                color: _rarityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.center,
              child: Text(
                _rarityLabel,
                style: AppTextStyles.badge.copyWith(
                  fontSize: 9,
                  color: _rarityColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}