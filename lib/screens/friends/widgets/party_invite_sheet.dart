import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/friends_provider.dart';
import '../../../providers/party_provider.dart';
import '../../../widgets/guild_avatar.dart';
import '../../party/party_lobby_screen.dart';

/// Bottom sheet showing current party members and a "Create Party" CTA.
/// Members were toggled via the [+ Party] button on each friend tile.
class PartyInviteSheet extends ConsumerWidget {
  const PartyInviteSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(partyMembersProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          0, 0, 0, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Your Party',
                  style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 22,
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${members.length}/5',
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.accentHover,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted, size: 22),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (members.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Text(
                'Tap "+ Party" on friends to invite them here',
                style: AppTextStyles.chatPreview.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            // Member avatar row
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: members.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final m = members[i];
                  return Column(
                    children: [
                      Stack(
                        children: [
                          GuildAvatar(
                            initial: m.avatarInitial,
                            colorIndex: m.avatarColorIndex,
                            size: 46,
                            status: m.status,
                          ),
                          Positioned(
                            top: -3, right: -3,
                            child: GestureDetector(
                              onTap: () => togglePartyMember(ref, m.id),
                              child: Container(
                                width: 18, height: 18,
                                decoration: const BoxDecoration(
                                  color: AppColors.bgElevated,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded,
                                    size: 11, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m.name.split(' ').first,
                        style: AppTextStyles.chatTime.copyWith(fontSize: 10),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Create party button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  // Create the party session from selected friends
                  ref.read(activePartyProvider.notifier).createParty();
                  // Close the sheet then push the lobby
                  Navigator.pop(context);
                  Navigator.of(context).push(PartyLobbyScreen.route());
                },
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sports_esports_outlined,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Create Party (${members.length})',
                        style: AppTextStyles.chatName.copyWith(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Group chat option
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          color: AppColors.textSecondary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Create Group Chat',
                        style: AppTextStyles.chatName.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}