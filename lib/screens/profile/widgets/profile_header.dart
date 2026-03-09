import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/chat_model.dart';
import '../../../models/profile_model.dart';
import '../../../widgets/guild_avatar.dart';
import '../../../widgets/status_dot.dart';

/// The top card of the profile screen.
/// Contains avatar, name, handle, bio, level + XP bar, and social stats.
class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onEdit,
  });

  final UserProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          // ── Avatar row ────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + level badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _ProfileAvatar(
                    profile: profile,
                    size: 72,
                  ),
                  // Level badge
                  Positioned(
                    bottom: -6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.bgElevated, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Lv ${profile.level}',
                          style: AppTextStyles.badge.copyWith(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // Name + handle + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: AppTextStyles.screenTitle.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.handle,
                      style: AppTextStyles.chatPreview.copyWith(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        StatusDot(status: profile.status, size: 8),
                        const SizedBox(width: 5),
                        Text(
                          _statusLabel(profile.status),
                          style: AppTextStyles.chatPreview.copyWith(
                            fontSize: 12.5,
                            color: _statusColor(profile.status),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Edit button
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 5),
                      Text(
                        'Edit',
                        style: AppTextStyles.sectionLabel.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Bio ───────────────────────────────────────────────
          if (profile.bio.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                profile.bio,
                style: AppTextStyles.chatPreview.copyWith(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // ── XP bar ────────────────────────────────────────────
          _XpBar(profile: profile),

          const SizedBox(height: 16),

          // ── Stats row (friends / groups / points) ─────────────
          _StatsRow(profile: profile),
        ],
      ),
    );
  }

  String _statusLabel(UserStatus s) => switch (s) {
        UserStatus.online  => 'Online',
        UserStatus.inGame  => 'In Game',
        UserStatus.idle    => 'Idle',
        UserStatus.offline => 'Offline',
      };

  Color _statusColor(UserStatus s) => switch (s) {
        UserStatus.online  => AppColors.success,
        UserStatus.inGame  => AppColors.accent,
        UserStatus.idle    => AppColors.warning,
        UserStatus.offline => AppColors.textMuted,
      };
}

// ── XP progress bar ────────────────────────────────────────────────────────

class _XpBar extends StatelessWidget {
  const _XpBar({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level ${profile.level}',
              style: AppTextStyles.sectionLabel.copyWith(
                fontSize: 11.5,
                color: AppColors.accentHover,
              ),
            ),
            Text(
              '${profile.xp.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} / ${profile.xpToNext.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} XP',
              style: AppTextStyles.chatTime.copyWith(fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: profile.xpProgress,
            backgroundColor: AppColors.bgCard,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ── Stats row ──────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCell(value: '${profile.totalFriends}', label: 'Friends')),
        _Divider(),
        Expanded(child: _StatCell(value: '${profile.totalGroups}', label: 'Groups')),
        _Divider(),
        Expanded(
          child: _StatCell(
            value: profile.guildPoints
                .toString()
                .replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (m) => '${m[1]},'),
            label: 'GP',
          ),
        ),
        _Divider(),
        Expanded(
          child: _StatCell(
            value: '${profile.achievements.length}',
            label: 'Badges',
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.chatName.copyWith(
            fontSize: 17,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.chatTime.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.border,
    );
  }
}

// ── Profile avatar (network URL or gradient fallback) ──────────────────────

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile, required this.size});
  final UserProfile profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GuildAvatar(
      initial: profile.avatarInitial,
      colorIndex: profile.avatarColorIndex,
      size: size,
      status: profile.status,
      dotBorderColor: AppColors.bgElevated,
    );
  }
}