import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Shows a confirmation bottom sheet before disbanding the party session.
/// Returns true if the user confirms, false / null if they cancel.
Future<bool?> showDisbandConfirmation(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.bgElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _DisbandSheet(),
  );
}

class _DisbandSheet extends StatelessWidget {
  const _DisbandSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.danger.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.exit_to_app_rounded,
              color: AppColors.danger,
              size: 26,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Leave Party?',
            style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
          ),

          const SizedBox(height: 8),

          Text(
            'This is a session-only party. Leaving will disband it for everyone.',
            style: AppTextStyles.chatPreview.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Confirm
          GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                'Leave & Disband',
                style: AppTextStyles.chatName.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Cancel
          GestureDetector(
            onTap: () => Navigator.pop(context, false),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                'Stay in Party',
                style: AppTextStyles.chatName.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}