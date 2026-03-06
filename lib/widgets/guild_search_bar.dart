import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/chat_provider.dart';

/// Rounded search field that updates [searchQueryProvider] on every keystroke.
/// Displays a clear button when the query is non-empty.
class GuildSearchBar extends ConsumerStatefulWidget {
  const GuildSearchBar({
    super.key,
    this.hintText = 'Search chats, players…',
  });

  final String hintText;

  @override
  ConsumerState<GuildSearchBar> createState() => _GuildSearchBarState();
}

class _GuildSearchBarState extends ConsumerState<GuildSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
    setState(() {}); // rebuild to show/hide clear button
  }

  void _onClear() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(
            Icons.search_rounded,
            size: 18,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              style: AppTextStyles.searchText,
              cursorColor: AppColors.accent,
              cursorWidth: 1.5,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTextStyles.searchHint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (hasText) ...[
            GestureDetector(
              onTap: _onClear,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ] else
            const SizedBox(width: 10),
        ],
      ),
    );
  }
}