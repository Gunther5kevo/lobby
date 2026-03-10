import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/group_model.dart';
import '../../../providers/groups_provider.dart';
import '../../../widgets/guild_avatar.dart';

/// Bottom sheet for discovering and joining public gaming communities.
/// Streams live from Firestore — filtered by tag via [browseTagProvider].
class BrowseGroupsSheet extends ConsumerWidget {
  const BrowseGroupsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      expand:           false,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color:        AppColors.bgElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color:        AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Browse Communities',
                      style: AppTextStyles.screenTitle.copyWith(fontSize: 18)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted, size: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tag filter chips
            const _TagFilterRow(),
            const SizedBox(height: 6),

            // Results
            const Expanded(child: _GroupResults()),
          ],
        ),
      ),
    );
  }
}

// ── Tag filter chips ───────────────────────────────────────────────────────

const _kTags = ['All', 'FPS', 'Esports', 'Casual', 'Ranked', 'EU', 'NA'];

class _TagFilterRow extends ConsumerWidget {
  const _TagFilterRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(browseTagProvider);
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: _kTags.map((tag) {
          final isActive = tag == 'All' ? active.isEmpty : active == tag;
          return GestureDetector(
            onTap: () => ref.read(browseTagProvider.notifier).state =
                tag == 'All' ? '' : tag,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin:   const EdgeInsets.only(right: 7),
              padding:  const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isActive ? AppColors.accentSoft : AppColors.bgCard,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isActive
                      ? AppColors.accent.withOpacity(0.3)
                      : AppColors.border,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                tag,
                style: AppTextStyles.sectionLabel.copyWith(
                  fontSize:    12,
                  letterSpacing: 0.05,
                  color: isActive
                      ? AppColors.accentHover
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Live results list ──────────────────────────────────────────────────────

class _GroupResults extends ConsumerWidget {
  const _GroupResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(publicGroupsProvider);
    final myGroups    = ref.watch(myGroupsProvider).valueOrNull ?? [];
    final myGroupIds  = myGroups.map((g) => g.id).toSet();

    return groupsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
      ),
      error: (_, __) => Center(
        child: Text('Could not load communities',
            style: AppTextStyles.chatPreview.copyWith(color: AppColors.textMuted)),
      ),
      data: (groups) {
        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.explore_off_outlined,
                    size: 44, color: AppColors.textMuted),
                const SizedBox(height: 10),
                Text('No communities found',
                    style: AppTextStyles.chatPreview
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding:          const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount:        groups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final g        = groups[i];
            final isJoined = myGroupIds.contains(g.id);
            return _GroupCard(group: g, isJoined: isJoined);
          },
        );
      },
    );
  }
}

// ── Group card ─────────────────────────────────────────────────────────────

class _GroupCard extends ConsumerStatefulWidget {
  const _GroupCard({required this.group, required this.isJoined});
  final Group group;
  final bool  isJoined;

  @override
  ConsumerState<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends ConsumerState<_GroupCard> {
  bool _joining = false;

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : n.toString();

  Future<void> _join() async {
    if (_joining || widget.isJoined) return;
    setState(() => _joining = true);
    HapticFeedback.lightImpact();
    try {
      await ref.read(groupsActionProvider.notifier).joinGroup(widget.group.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:          Text('Joined ${widget.group.name}!'),
          backgroundColor:  AppColors.bgElevated,
          behavior:         SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g        = widget.group;
    final isJoined = widget.isJoined;

    return Container(
      padding:    const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          GuildAvatar(
            initial:    g.emoji,
            emoji:      g.emoji,
            colorIndex: g.avatarColorIndex,
            size:       50,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.name, style: AppTextStyles.chatName),
                const SizedBox(height: 3),
                Text(
                  g.description,
                  style:     AppTextStyles.chatPreview.copyWith(fontSize: 12),
                  maxLines:  2,
                  overflow:  TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.people_outline_rounded,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('${_fmt(g.memberCount)} members',
                        style: AppTextStyles.chatPreview
                            .copyWith(fontSize: 11.5, color: AppColors.textMuted)),
                    const SizedBox(width: 10),
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success, shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('${_fmt(g.onlineCount)} online',
                        style: AppTextStyles.chatPreview.copyWith(
                            fontSize: 11.5, color: AppColors.success)),
                  ],
                ),
                // Tags
                if (g.tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing:    5,
                    runSpacing: 3,
                    children: g.tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color:        AppColors.bgElevated,
                        borderRadius: BorderRadius.circular(5),
                        border:       Border.all(color: AppColors.border),
                      ),
                      child: Text(t,
                          style: AppTextStyles.sectionLabel
                              .copyWith(fontSize: 10, color: AppColors.textMuted)),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isJoined ? null : _join,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height:   32,
              padding:  const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isJoined ? AppColors.bgElevated : AppColors.accentSoft,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isJoined
                      ? AppColors.border
                      : AppColors.accent.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_joining)
                    const SizedBox(
                      width: 13, height: 13,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: AppColors.accent),
                    )
                  else
                    Icon(
                      isJoined ? Icons.check_rounded : Icons.add_rounded,
                      size:  14,
                      color: isJoined
                          ? AppColors.textMuted
                          : AppColors.accentHover,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    isJoined ? 'Joined' : 'Join',
                    style: AppTextStyles.sectionLabel.copyWith(
                      fontSize: 12,
                      color: isJoined
                          ? AppColors.textMuted
                          : AppColors.accentHover,
                      letterSpacing: 0.05,
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