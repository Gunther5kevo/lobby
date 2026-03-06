import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/friend_model.dart';
import '../../providers/friends_provider.dart';
import '../../widgets/section_header.dart';
import '../conversation/conversation_screen.dart';
import '../chats/chats_screen.dart' show _StubBuilder;
import 'widgets/filter_chips_row.dart';
import 'widgets/friend_list_tile.dart';
import 'widgets/friend_request_tile.dart';
import 'widgets/friends_app_bar.dart';
import 'widgets/online_strip.dart';
import 'widgets/add_friend_sheet.dart';
import 'widgets/party_invite_sheet.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections  = ref.watch(friendSectionsProvider);
    final requests  = ref.watch(friendRequestsProvider);
    final party     = ref.watch(partyMembersProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── App bar ───────────────────────────────────────
                FriendsAppBar(
                  onAddFriend: () => _showAddFriendSheet(context),
                ),

                // ── Filter chips ──────────────────────────────────
                const FriendFilterChipsRow(),

                // ── Online strip ──────────────────────────────────
                const OnlineStrip(),

                const SizedBox(height: 6),

                // ── List ──────────────────────────────────────────
                Expanded(
                  child: sections.isEmpty && requests.isEmpty
                      ? _EmptyState()
                      : CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            // Pending requests section
                            if (requests.isNotEmpty) ...[
                              SliverToBoxAdapter(
                                child: SectionHeader(
                                  title:
                                      'Requests (${requests.length})',
                                ),
                              ),
                              SliverList.separated(
                                itemCount: requests.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(indent: 80, height: 0),
                                itemBuilder: (_, i) =>
                                    FriendRequestTile(request: requests[i]),
                              ),
                            ],

                            // In game
                            if (sections.inGame.isNotEmpty)
                              ..._buildSection(
                                context, ref,
                                title: 'In Game',
                                friends: sections.inGame,
                              ),

                            // Online
                            if (sections.online.isNotEmpty)
                              ..._buildSection(
                                context, ref,
                                title: 'Online',
                                friends: sections.online,
                              ),

                            // Idle
                            if (sections.idle.isNotEmpty)
                              ..._buildSection(
                                context, ref,
                                title: 'Idle',
                                friends: sections.idle,
                              ),

                            // Offline
                            if (sections.offline.isNotEmpty)
                              ..._buildSection(
                                context, ref,
                                title: 'Offline',
                                friends: sections.offline,
                              ),

                            // Bottom padding for nav bar + FAB
                            const SliverPadding(
                              padding: EdgeInsets.only(bottom: 100),
                            ),
                          ],
                        ),
                ),
              ],
            ),

            // ── Party FAB ─────────────────────────────────────────
            if (party.isNotEmpty)
              Positioned(
                right: 16,
                bottom: 16,
                child: _PartyFAB(
                  count: party.length,
                  onTap: () => _showPartySheet(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<SliverWidget> _buildSection(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required List<Friend> friends,
  }) {
    return [
      SliverToBoxAdapter(child: SectionHeader(title: title)),
      SliverList.separated(
        itemCount: friends.length,
        separatorBuilder: (_, __) =>
            const Divider(indent: 80, height: 0),
        itemBuilder: (_, i) {
          final f = friends[i];
          return FriendListTile(
            friend: f,
            onMessage: () {
              // Build a minimal ChatPreview to open conversation
              // In prod this would be looked up from the chat repo
            },
          );
        },
      ),
    ];
  }

  void _showAddFriendSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddFriendSheet(),
    );
  }

  void _showPartySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const PartyInviteSheet(),
    );
  }
}

// ── Section helper type ────────────────────────────────────────────────────

typedef SliverWidget = Widget;

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline_rounded,
              size: 52, color: AppColors.textMuted),
          const SizedBox(height: 14),
          Text(
            'No friends found',
            style: AppTextStyles.chatName.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different filter or add new friends',
            style: AppTextStyles.chatPreview,
          ),
        ],
      ),
    );
  }
}

// ── Party FAB ──────────────────────────────────────────────────────────────

class _PartyFAB extends StatelessWidget {
  const _PartyFAB({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sports_esports_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Party ($count)',
              style: AppTextStyles.chatName.copyWith(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}