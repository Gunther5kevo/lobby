import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/chat_model.dart';
import '../../../models/friend_model.dart';
import '../../../providers/friends_provider.dart';
import '../../../widgets/guild_avatar.dart';

/// Bottom sheet for finding and adding new friends.
/// Has a search field and a list of suggested players.
class AddFriendSheet extends ConsumerStatefulWidget {
  const AddFriendSheet({super.key});

  @override
  ConsumerState<AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends ConsumerState<AddFriendSheet> {
  final _controller = TextEditingController();

  // Suggested players (not already friends)
  static const _suggestions = [
    (name: 'PixelStorm', handle: '#pxstorm', colorIdx: 0, emoji: '⚡',
     game: 'Valorant', status: UserStatus.inGame),
    (name: 'ObsidianFox', handle: '#obsfox', colorIdx: 5, emoji: '🦊',
     game: null, status: UserStatus.online),
    (name: 'HexBlade', handle: '#hex_b', colorIdx: 2, emoji: '🔮',
     game: 'Apex Legends', status: UserStatus.inGame),
    (name: 'TitanFall77', handle: '#titanf', colorIdx: 3, emoji: '🤖',
     game: null, status: UserStatus.idle),
    (name: 'LunarEclipse', handle: '#lunar_e', colorIdx: 4, emoji: '🌙',
     game: 'League of Legends', status: UserStatus.inGame),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(addFriendQueryProvider).toLowerCase();
    final filtered = _suggestions
        .where((s) =>
            query.isEmpty ||
            s.name.toLowerCase().contains(query) ||
            s.handle.toLowerCase().contains(query))
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        0, 0, 0, MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
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
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Add Friends', style: AppTextStyles.screenTitle.copyWith(fontSize: 18)),
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

          // Search input
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
                      controller: _controller,
                      autofocus: true,
                      onChanged: (v) =>
                          ref.read(addFriendQueryProvider.notifier).state = v,
                      style: AppTextStyles.searchText,
                      cursorColor: AppColors.accent,
                      cursorWidth: 1.5,
                      decoration: InputDecoration(
                        hintText: 'Search by name or #handle…',
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

          // Suggested header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                query.isEmpty ? 'Suggested' : 'Results',
                style: AppTextStyles.sectionLabel,
              ),
            ),
          ),

          // Suggestions list
          ...filtered.map((s) => _SuggestionTile(
                name: s.name,
                handle: s.handle,
                colorIdx: s.colorIdx,
                status: s.status,
                gameName: s.game,
                onAdd: () {
                  HapticFeedback.lightImpact();
                  ref.read(friendListProvider.notifier).addFriend(
                    Friend(
                      id: 'new_${s.handle}',
                      name: s.name,
                      handle: s.handle,
                      avatarInitial: s.name[0],
                      avatarColorIndex: s.colorIdx,
                      status: s.status,
                    ),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Friend request sent to ${s.name}'),
                      backgroundColor: AppColors.bgElevated,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              )),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatefulWidget {
  const _SuggestionTile({
    required this.name,
    required this.handle,
    required this.colorIdx,
    required this.status,
    required this.onAdd,
    this.gameName,
  });

  final String name;
  final String handle;
  final int colorIdx;
  final UserStatus status;
  final String? gameName;
  final VoidCallback onAdd;

  @override
  State<_SuggestionTile> createState() => _SuggestionTileState();
}

class _SuggestionTileState extends State<_SuggestionTile> {
  bool _requested = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          GuildAvatar(
            initial: widget.name[0],
            colorIndex: widget.colorIdx,
            size: 44,
            status: widget.status,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name, style: AppTextStyles.chatName),
                Text(
                  widget.gameName != null
                      ? '🎮 ${widget.gameName}'
                      : widget.handle,
                  style: AppTextStyles.chatPreview.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _requested ? null : () {
              setState(() => _requested = true);
              widget.onAdd();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _requested ? AppColors.bgCard : AppColors.accentSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _requested
                      ? AppColors.border
                      : AppColors.accent.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    _requested ? 'Requested' : 'Add',
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