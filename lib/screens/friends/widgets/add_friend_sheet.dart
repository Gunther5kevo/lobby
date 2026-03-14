import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/firestore_providers.dart';
import '../../../providers/friends_provider.dart';
import '../../../widgets/guild_avatar.dart';
import '../../../models/chat_model.dart';

/// Bottom sheet for finding and adding new friends by #handle.
/// Searches Firestore in real time as the user types.
class AddFriendSheet extends ConsumerStatefulWidget {
  const AddFriendSheet({super.key});

  @override
  ConsumerState<AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends ConsumerState<AddFriendSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    ref.read(addFriendQueryProvider.notifier).state = ''; // ref before super
    _controller.dispose();
    super.dispose(); // always last
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return; // guard against sheet closing mid-debounce
      ref.read(addFriendQueryProvider.notifier).state = value.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(userSearchProvider);
    final query = ref.watch(addFriendQueryProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        0, 0, 0, MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle bar
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

          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Add Friends',
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
          const SizedBox(height: 6),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Search by #handle to find players',
              style: AppTextStyles.chatPreview
                  .copyWith(color: AppColors.textMuted, fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 14),

          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
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
                      controller: _controller,
                      autofocus: true,
                      onChanged: _onChanged,
                      style: AppTextStyles.searchText.copyWith(fontSize: 14),
                      cursorColor: AppColors.accent,
                      cursorWidth: 1.5,
                      decoration: InputDecoration(
                        hintText: '#handle…',
                        hintStyle: AppTextStyles.searchHint,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        ref.read(addFriendQueryProvider.notifier).state = '';
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: AppColors.textMuted),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Results area
          _ResultsArea(
            query: query,
            resultsAsync: resultsAsync,
            onSent: () => Navigator.pop(context),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// ── Results area ───────────────────────────────────────────────────────────

class _ResultsArea extends ConsumerWidget {
  const _ResultsArea({
    required this.query,
    required this.resultsAsync,
    required this.onSent,
  });

  final String query;
  final AsyncValue<List<Map<String, dynamic>>> resultsAsync;
  final VoidCallback onSent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Empty state — no query yet
    if (query.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(Icons.manage_search_rounded,
                size: 40, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(
              'Type a #handle to search',
              style: AppTextStyles.chatPreview
                  .copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return resultsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.accent, strokeWidth: 2),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Text(
          'Search failed. Check your connection.',
          style: AppTextStyles.chatPreview
              .copyWith(color: AppColors.textMuted),
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const Icon(Icons.search_off_rounded,
                    size: 40, color: AppColors.textMuted),
                const SizedBox(height: 10),
                Text(
                  'No players found for "$query"',
                  style: AppTextStyles.chatPreview
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                '${results.length} player${results.length == 1 ? '' : 's'} found',
                style: AppTextStyles.sectionLabel.copyWith(fontSize: 11.5),
              ),
            ),
            ...results.map((user) => _UserResultTile(
                  user: user,
                  onSent: onSent,
                )),
          ],
        );
      },
    );
  }
}

// ── Single user result tile ────────────────────────────────────────────────

class _UserResultTile extends ConsumerStatefulWidget {
  const _UserResultTile({required this.user, required this.onSent});
  final Map<String, dynamic> user;
  final VoidCallback onSent;

  @override
  ConsumerState<_UserResultTile> createState() => _UserResultTileState();
}

class _UserResultTileState extends ConsumerState<_UserResultTile> {
  bool _requested = false;
  bool _sending = false;

  Future<void> _sendRequest() async {
    if (_requested || _sending) return;
    setState(() => _sending = true);
    HapticFeedback.lightImpact();

    try {
      final toUid = widget.user['uid'] as String? ?? '';
      await ref.read(friendsActionProvider.notifier).sendRequest(toUid);
      if (mounted) setState(() { _requested = true; _sending = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Friend request sent to ${widget.user['displayName'] ?? 'player'}'),
          backgroundColor: AppColors.bgElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name  = widget.user['displayName'] as String? ?? 'Player';
    final handle = widget.user['handle'] as String? ?? '#unknown';
    final colorIndex = widget.user['avatarColorIndex'] as int? ?? 0;
    final level = widget.user['level'] as int? ?? 1;
    final statusStr = widget.user['status'] as String? ?? 'offline';
    final status = UserStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => UserStatus.offline,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      child: Row(
        children: [
          GuildAvatar(
            initial: name.isNotEmpty ? name[0].toUpperCase() : '?',
            colorIndex: colorIndex,
            size: 46,
            status: status,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: AppTextStyles.chatName),
                    const SizedBox(width: 6),
                    Container(
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Lv $level',
                        style: AppTextStyles.badge.copyWith(
                          fontSize: 9, color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  handle,
                  style: AppTextStyles.chatPreview.copyWith(
                    fontSize: 12, color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Add button
          GestureDetector(
            onTap: _requested ? null : _sendRequest,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _requested
                    ? AppColors.bgCard
                    : AppColors.accentSoft,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: _requested
                      ? AppColors.border
                      : AppColors.accent.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_sending)
                    const SizedBox(
                      width: 13, height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: AppColors.accent,
                      ),
                    )
                  else
                    Icon(
                      _requested
                          ? Icons.check_rounded
                          : Icons.person_add_outlined,
                      size: 13,
                      color: _requested
                          ? AppColors.textMuted
                          : AppColors.accentHover,
                    ),
                  const SizedBox(width: 5),
                  Text(
                    _requested ? 'Sent' : 'Add',
                    style: AppTextStyles.sectionLabel.copyWith(
                      fontSize: 11.5,
                      color: _requested
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