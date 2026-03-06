import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/chat_model.dart';

/// Small coloured dot shown on avatar corners.
/// Size defaults to 12 logical pixels with a 2px border
/// matching the background so it "punches out" of the avatar.
class StatusDot extends StatelessWidget {
  const StatusDot({
    super.key,
    required this.status,
    this.size = 12,
    this.borderColor = AppColors.bgBase,
  });

  final UserStatus status;
  final double size;

  /// Set this to the colour of whatever the dot sits on top of
  /// so the border cutout matches perfectly.
  final Color borderColor;

  Color get _dotColor {
    switch (status) {
      case UserStatus.online:
        return AppColors.success;
      case UserStatus.inGame:
        return AppColors.accent;
      case UserStatus.idle:
        return AppColors.warning;
      case UserStatus.offline:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _dotColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
    );
  }
}