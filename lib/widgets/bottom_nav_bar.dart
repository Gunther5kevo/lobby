import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/chat_provider.dart';

class GuildBottomNavBar extends ConsumerWidget {
  const GuildBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navIndexProvider);
    final totalUnread  = ref.watch(totalUnreadProvider);

    return Container(
      height: 82,
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          _NavItem(
            index: 0,
            currentIndex: currentIndex,
            icon: Icons.chat_bubble_outline_rounded,
            iconActive: Icons.chat_bubble_rounded,
            label: 'Chats',
            badge: totalUnread,
            onTap: () => ref.read(navIndexProvider.notifier).state = 0,
          ),
          _NavItem(
            index: 1,
            currentIndex: currentIndex,
            icon: Icons.people_outline_rounded,
            iconActive: Icons.people_rounded,
            label: 'Friends',
            onTap: () => ref.read(navIndexProvider.notifier).state = 1,
          ),
          _NavItem(
            index: 2,
            currentIndex: currentIndex,
            icon: Icons.tv_outlined,
            iconActive: Icons.tv_rounded,
            label: 'Groups',
            onTap: () => ref.read(navIndexProvider.notifier).state = 2,
          ),
          _NavItem(
            index: 3,
            currentIndex: currentIndex,
            icon: Icons.person_outline_rounded,
            iconActive: Icons.person_rounded,
            label: 'Profile',
            onTap: () => ref.read(navIndexProvider.notifier).state = 3,
          ),
        ],
      ),
    );
  }
}

// ── Individual nav item ────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.iconActive,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData iconActive;
  final String label;
  final VoidCallback onTap;
  final int badge;

  bool get _isActive => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon + optional badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 36,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _isActive
                          ? AppColors.accentSoft
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      _isActive ? iconActive : icon,
                      size: 22,
                      color: _isActive
                          ? AppColors.accent
                          : AppColors.textMuted,
                    ),
                  ),
                  if (badge > 0 && !_isActive)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        height: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.bgSurface,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          badge > 99 ? '99+' : badge.toString(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.navLabel.copyWith(
                  color: _isActive
                      ? AppColors.accent
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}