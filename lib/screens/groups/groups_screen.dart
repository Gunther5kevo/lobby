import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/group_model.dart';
import '../../providers/groups_provider.dart';
import 'widgets/browse_groups_sheet.dart';
import 'widgets/group_channel_screen.dart';
import 'widgets/group_list_tile.dart';
import 'widgets/groups_app_bar.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync   = ref.watch(groupsWithChannelsProvider);
    final groups        = ref.watch(filteredGroupsProvider);
    final activeGroupId = ref.watch(activeGroupIdProvider);
    final query         = ref.watch(groupSearchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GroupsAppBar(onBrowse: () => _showBrowseSheet(context)),

            Expanded(
              child: groupsAsync.isLoading && groups.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accent, strokeWidth: 2))
                  : groups.isEmpty
                      ? _EmptyState(isSearch: query.isNotEmpty)
                      : CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverList.separated(
                              itemCount:        groups.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 0, indent: 20, endIndent: 20),
                              itemBuilder: (context, i) {
                                final group = groups[i];
                                return GroupListTile(
                                  group:      group,
                                  isExpanded: activeGroupId == group.id,
                                  onToggleExpand: () {
                                    ref.read(activeGroupIdProvider.notifier).state =
                                        activeGroupId == group.id
                                            ? null
                                            : group.id;
                                  },
                                  onChannelTap: (channel) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => GroupChannelScreen(
                                          group:   group,
                                          channel: channel,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            SliverToBoxAdapter(
                              child: _BrowseCTA(
                                  onTap: () => _showBrowseSheet(context)),
                            ),
                            const SliverPadding(
                                padding: EdgeInsets.only(bottom: 20)),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBrowseSheet(BuildContext context) {
    showModalBottomSheet(
      context:           context,
      isScrollControlled: true,
      backgroundColor:   Colors.transparent,
      builder: (_) => const BrowseGroupsSheet(),
    );
  }
}

// ── Browse CTA ─────────────────────────────────────────────────────────────

class _BrowseCTA extends StatelessWidget {
  const _BrowseCTA({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        height: 48,
        decoration: BoxDecoration(
          color:        AppColors.bgElevated,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: AppColors.borderStrong, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.explore_outlined,
                size: 18, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Text(
              'Browse Communities',
              style: AppTextStyles.chatName.copyWith(
                fontSize:   14,
                color:      AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isSearch});
  final bool isSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearch
                ? Icons.search_off_rounded
                : Icons.people_outline_rounded,
            size:  52,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 14),
          Text(
            isSearch ? 'No groups found' : 'No groups yet',
            style: AppTextStyles.chatName.copyWith(
              color:      AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearch
                ? 'Try a different name or tag'
                : 'Browse communities to find your squad',
            style: AppTextStyles.chatPreview,
          ),
        ],
      ),
    );
  }
}