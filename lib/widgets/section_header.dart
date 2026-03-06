import 'package:flutter/material.dart';
import '../core/theme/app_text_styles.dart';

/// "PINNED" / "RECENT" divider label used between chat list sections.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.sectionLabel,
      ),
    );
  }
}