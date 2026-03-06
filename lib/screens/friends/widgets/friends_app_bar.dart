import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/friends_provider.dart';

/// App bar for the Friends screen.
/// Collapses into a search field when [isSearching] is true.
class FriendsAppBar extends ConsumerStatefulWidget {
  const FriendsAppBar({
    super.key,
    this.onAddFriend,
  });

  final VoidCallback? onAddFriend;

  @override
  ConsumerState<FriendsAppBar> createState() => _FriendsAppBarState();
}

class _FriendsAppBarState extends ConsumerState<FriendsAppBar> {
  bool _isSearching = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startSearch() => setState(() => _isSearching = true);

  void _stopSearch() {
    setState(() => _isSearching = false);
    _controller.clear();
    ref.read(friendSearchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        children: [
          // Title or search field
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isSearching
                  ? _SearchField(
                      key: const ValueKey('search'),
                      controller: _controller,
                      onChanged: (v) => ref
                          .read(friendSearchQueryProvider.notifier)
                          .state = v,
                      onClose: _stopSearch,
                    )
                  : Align(
                      key: const ValueKey('title'),
                      alignment: Alignment.centerLeft,
                      child: Text('Friends', style: AppTextStyles.screenTitle),
                    ),
            ),
          ),

          if (!_isSearching) ...[
            const SizedBox(width: 10),

            // Search icon button
            _HeaderBtn(
              icon: Icons.search_rounded,
              onTap: _startSearch,
            ),

            const SizedBox(width: 8),

            // Add friend button
            _HeaderBtn(
              icon: Icons.person_add_outlined,
              onTap: widget.onAddFriend,
              isPrimary: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search_rounded,
                    size: 18, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: onChanged,
                    style: AppTextStyles.searchText,
                    cursorColor: AppColors.accent,
                    cursorWidth: 1.5,
                    decoration: InputDecoration(
                      hintText: 'Find players…',
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
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onClose,
          child: Text(
            'Cancel',
            style: AppTextStyles.chatPreview.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  const _HeaderBtn({
    required this.icon,
    this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.accentSoft : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPrimary
                ? AppColors.accent.withOpacity(0.25)
                : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isPrimary ? AppColors.accent : AppColors.textSecondary,
        ),
      ),
    );
  }
}