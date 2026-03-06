import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/groups_provider.dart';

class GroupsAppBar extends ConsumerStatefulWidget {
  const GroupsAppBar({super.key, this.onBrowse});
  final VoidCallback? onBrowse;

  @override
  ConsumerState<GroupsAppBar> createState() => _GroupsAppBarState();
}

class _GroupsAppBarState extends ConsumerState<GroupsAppBar> {
  bool _searching = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _searching
                  ? _SearchField(
                      key: const ValueKey('s'),
                      controller: _ctrl,
                      onChanged: (v) =>
                          ref.read(groupSearchQueryProvider.notifier).state = v,
                      onClose: () {
                        setState(() => _searching = false);
                        _ctrl.clear();
                        ref.read(groupSearchQueryProvider.notifier).state = '';
                      },
                    )
                  : Align(
                      key: const ValueKey('t'),
                      alignment: Alignment.centerLeft,
                      child: Text('Groups', style: AppTextStyles.screenTitle),
                    ),
            ),
          ),
          if (!_searching) ...[
            const SizedBox(width: 10),
            _Btn(
              icon: Icons.search_rounded,
              onTap: () => setState(() => _searching = true),
            ),
            const SizedBox(width: 8),
            _Btn(
              icon: Icons.add_rounded,
              onTap: widget.onBrowse,
              primary: true,
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

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, this.onTap, this.primary = false});
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: primary ? AppColors.accentSoft : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: primary
                ? AppColors.accent.withOpacity(0.25)
                : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: primary ? AppColors.accent : AppColors.textSecondary,
        ),
      ),
    );
  }
}