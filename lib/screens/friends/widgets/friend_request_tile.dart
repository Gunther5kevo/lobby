import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/friend_model.dart';
import '../../../providers/friends_provider.dart';
import '../../../widgets/guild_avatar.dart';

/// Incoming friend request row.
/// Shows avatar, name, mutual friends count, and Accept / Decline buttons.
class FriendRequestTile extends ConsumerWidget {
  const FriendRequestTile({
    super.key,
    required this.request,
  });

  final FriendRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friend = request.friend;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Avatar (no status dot on requests)
          GuildAvatar(
            initial: friend.avatarInitial,
            colorIndex: friend.avatarColorIndex,
            size: 48,
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.name, style: AppTextStyles.chatName),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (friend.mutualFriends > 0) ...[
                      const Icon(Icons.people_outline_rounded,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${friend.mutualFriends} mutual',
                        style: AppTextStyles.chatPreview.copyWith(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (friend.mutualFriends > 0 &&
                        friend.activity != null) ...[
                      Text(
                        ' · ',
                        style: AppTextStyles.chatPreview.copyWith(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (friend.activity != null) ...[
                      Text(
                        friend.activity!.gameEmoji,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        friend.activity!.gameName,
                        style: AppTextStyles.chatPreview.copyWith(
                          fontSize: 12,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Accept / Decline
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decline
              _RequestBtn(
                icon: Icons.close_rounded,
                color: AppColors.bgElevated,
                iconColor: AppColors.textMuted,
                borderColor: AppColors.border,
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref
                      .read(friendRequestsProvider.notifier)
                      .decline(request.id);
                },
              ),
              const SizedBox(width: 7),
              // Accept
              _RequestBtn(
                icon: Icons.check_rounded,
                color: AppColors.accent,
                iconColor: Colors.white,
                borderColor: Colors.transparent,
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref
                      .read(friendRequestsProvider.notifier)
                      .accept(request.id);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestBtn extends StatelessWidget {
  const _RequestBtn({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.borderColor,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}