import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/friend_model.dart';
import '../../../providers/friends_provider.dart';

/// Horizontally scrollable row of filter chips.
/// Each chip shows the filter name and live count badge.
class FriendFilterChipsRow extends ConsumerWidget {
  const FriendFilterChipsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(friendFilterProvider);
    final counts = ref.watch(friendCountsProvider);

    final chips = [
      (FriendFilter.all,    'All',      counts.all),
      (FriendFilter.inGame, '🎮 In Game', counts.inGame),
      (FriendFilter.online, 'Online',   counts.online),
      (FriendFilter.idle,   'Idle',     counts.idle),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, i) {
          final (filter, label, count) = chips[i];
          return _FilterChip(
            label: label,
            count: count,
            isActive: active == filter,
            onTap: () => ref.read(friendFilterProvider.notifier).state = filter,
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentSoft : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColors.accent.withOpacity(0.3)
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.sectionLabel.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
                color: isActive ? AppColors.accentHover : AppColors.textSecondary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                height: 18,
                constraints: const BoxConstraints(minWidth: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.accent.withOpacity(0.2)
                      : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  count.toString(),
                  style: AppTextStyles.badge.copyWith(
                    fontSize: 10,
                    color: isActive
                        ? AppColors.accentHover
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}