import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/chat_model.dart';
import 'status_dot.dart';

/// Rounded-rectangle avatar with a gradient background.
/// Shows [emoji] when set, otherwise shows [initial].
/// Optionally overlays a [StatusDot] in the bottom-right corner.
class GuildAvatar extends StatelessWidget {
  const GuildAvatar({
    super.key,
    required this.initial,
    required this.colorIndex,
    this.emoji,
    this.size = 50,
    this.borderRadius,
    this.status,
    this.dotBorderColor = AppColors.bgBase,
  });

  final String initial;
  final int colorIndex;
  final String? emoji;

  /// Width and height of the avatar square.
  final double size;

  /// Defaults to size * 0.32 for a nicely rounded square.
  final double? borderRadius;

  /// When non-null, a [StatusDot] is drawn over the bottom-right corner.
  final UserStatus? status;

  final Color dotBorderColor;

  List<Color> get _gradient {
    final idx = colorIndex.clamp(0, AppColors.avatarGradients.length - 1);
    return AppColors.avatarGradients[idx];
  }

  double get _radius => borderRadius ?? size * 0.32;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradient,
        ),
        borderRadius: BorderRadius.circular(_radius),
      ),
      alignment: Alignment.center,
      child: _buildContent(),
    );

    if (status == null) return avatar;

    // Overlay status dot
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          bottom: -1,
          right: -1,
          child: StatusDot(
            status: status!,
            size: size * 0.24,
            borderColor: dotBorderColor,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    // Emoji avatar (groups / special)
    if (emoji != null && emoji!.isNotEmpty) {
      return Text(
        emoji!,
        style: TextStyle(fontSize: size * 0.42),
      );
    }
    // Initials
    return Text(
      initial.isNotEmpty ? initial[0].toUpperCase() : '?',
      style: size >= 48
          ? AppTextStyles.avatarInitial.copyWith(fontSize: size * 0.37)
          : AppTextStyles.avatarInitialSm.copyWith(fontSize: size * 0.35),
    );
  }
}