import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/group_model.dart';
import '../../../providers/groups_provider.dart';
import '../../../widgets/guild_avatar.dart';

/// Bottom sheet for discovering and joining new gaming communities.
class BrowseGroupsSheet extends ConsumerStatefulWidget {
  const BrowseGroupsSheet({super.key});

  @override
  ConsumerState<BrowseGroupsSheet> createState() =>
      _BrowseGroupsSheetState();
}

class _BrowseGroupsSheetState extends ConsumerState<BrowseGroupsSheet> {
  final _ctrl = TextEditingController();
  String _query = '';

  // Track joined state locally so buttons animate
  final Set<String> _joined = {};

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<Group> get _filtered {
    if (_query.isEmpty) return suggestedGroups;
    return suggestedGroups
        .where((g) =>
            g.name.toLowerCase().contains(_query.toLowerCase()) ||
            g.tags.any(
                (t) => t.toLowerCase().contains(_query.toLowerCase())))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
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
                    Text(
                      'Browse Communities',
                      style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
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
              const SizedBox(height: 12),

              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.bgInput,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const Icon(Icons.search_rounded,
                          size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          onChanged: (v) => setState(() => _query = v),
                          style: AppTextStyles.searchText,
                          cursorColor: AppColors.accent,
                          cursorWidth: 1.5,
                          decoration: InputDecoration(
                            hintText: 'Search communities…',
                            hintStyle: AppTextStyles.searchHint,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Tags row
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: ['All', 'FPS', 'Esports', 'Casual', 'Ranked', 'EU', 'NA']
                      .map((tag) => _TagChip(
                            label: tag,
                            isActive: _query == tag ||
                                (tag == 'All' && _query.isEmpty),
                            onTap: () => setState(() =>
                                _query = tag == 'All' ? '' : tag),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 6),

              // List
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final group = _filtered[i];
                    final isJoined = _joined.contains(group.id) ||
                        ref
                            .read(groupListProvider)
                            .any((g) => g.id == group.id);
                    return _BrowseGroupCard(
                      group: group,
                      isJoined: isJoined,
                      onJoin: () {
                        HapticFeedback.lightImpact();
                        setState(() => _joined.add(group.id));
                        ref
                            .read(groupListProvider.notifier)
                            .joinGroup(group);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Joined ${group.name}!'),
                            backgroundColor: AppColors.bgElevated,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Tag chip ───────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(horizontal: 14),
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
          label,
          style: AppTextStyles.sectionLabel.copyWith(
            fontSize: 12,
            letterSpacing: 0.05,
            color: isActive
                ? AppColors.accentHover
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Browse group card ──────────────────────────────────────────────────────

class _BrowseGroupCard extends StatelessWidget {
  const _BrowseGroupCard({
    required this.group,
    required this.isJoined,
    required this.onJoin,
  });
  final Group group;
  final bool isJoined;
  final VoidCallback onJoin;

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : n.toString();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          GuildAvatar(
            initial: group.emoji,
            emoji: group.emoji,
            colorIndex: group.avatarColorIndex,
            size: 50,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name, style: AppTextStyles.chatName),
                const SizedBox(height: 3),
                Text(
                  group.description,
                  style: AppTextStyles.chatPreview.copyWith(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.people_outline_rounded,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${_fmt(group.memberCount)} members',
                      style: AppTextStyles.chatPreview
                          .copyWith(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_fmt(group.onlineCount)} online',
                      style: AppTextStyles.chatPreview.copyWith(
                        fontSize: 11.5,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isJoined ? null : onJoin,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  Icon(
                    isJoined ? Icons.check_rounded : Icons.add_rounded,
                    size: 14,
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