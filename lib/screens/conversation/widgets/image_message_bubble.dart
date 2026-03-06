import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/message_model.dart';

/// Screenshot / clip message bubble.
/// Renders a styled gradient placeholder that mimics a game screenshot,
/// with an emoji, title, and subtitle overlaid.
///
/// In a real app this would display a [CachedNetworkImage] with the
/// same overlay applied via a [Stack].
class ImageMessageBubble extends StatelessWidget {
  const ImageMessageBubble({
    super.key,
    required this.image,
    required this.isMine,
  });

  final ImageAttachment image;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft:     const Radius.circular(14),
        topRight:    const Radius.circular(14),
        bottomLeft:  Radius.circular(isMine ? 14 : 4),
        bottomRight: Radius.circular(isMine ? 4 : 14),
      ),
      child: SizedBox(
        width: 210,
        height: 120,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient (simulates screenshot)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(image.gradientColors[0]),
                    Color(image.gradientColors[1]),
                  ],
                ),
              ),
            ),

            // Grid-dot pattern (subtle texture)
            CustomPaint(painter: _DotGridPainter()),

            // Dark overlay — bottom half only so text is readable
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                height: 60,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC050A14)],
                  ),
                ),
              ),
            ),

            // Emoji centred in upper half
            Positioned(
              top: 18,
              left: 0, right: 0,
              child: Text(
                image.emoji,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 30),
              ),
            ),

            // Label at bottom
            Positioned(
              left: 10, right: 10, bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    image.label,
                    style: AppTextStyles.chatName.copyWith(
                      fontSize: 12.5,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    image.sublabel,
                    style: AppTextStyles.chatPreview.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Subtle dot-grid texture ────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 16.0;
    const radius  = 1.0;
    final paint   = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}