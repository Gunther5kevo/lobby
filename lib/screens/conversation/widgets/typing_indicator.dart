import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Three animated bouncing dots shown when the other person is typing.
/// Each dot staggers its animation by 200ms.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  static const _dotCount   = 3;
  static const _dotSize    = 7.0;
  static const _jumpHeight = 5.0;
  static const _stagger    = Duration(milliseconds: 200);
  static const _period     = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(_dotCount, (i) {
      return AnimationController(vsync: this, duration: _period);
    });

    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0, end: _jumpHeight).animate(
        CurvedAnimation(
          parent: c,
          curve: const _BounceCurve(),
        ),
      );
    }).toList();

    // Start each dot with a stagger delay then loop forever
    for (int i = 0; i < _dotCount; i++) {
      Future.delayed(_stagger * i, () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: const BorderRadius.only(
              topLeft:     Radius.circular(14),
              topRight:    Radius.circular(14),
              bottomRight: Radius.circular(14),
              bottomLeft:  Radius.circular(4),
            ),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_dotCount, (i) {
              return AnimatedBuilder(
                animation: _animations[i],
                builder: (_, __) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: i < _dotCount - 1 ? 4 : 0,
                    ),
                    child: Transform.translate(
                      offset: Offset(0, -_animations[i].value),
                      child: Container(
                        width: _dotSize,
                        height: _dotSize,
                        decoration: const BoxDecoration(
                          color: AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }
}

/// Custom curve: ease up, ease down, brief pause at bottom.
class _BounceCurve extends Curve {
  const _BounceCurve();

  @override
  double transformInternal(double t) {
    // 0→0.4 rise, 0.4→0.7 fall, 0.7→1.0 rest at 0
    if (t < 0.4) return Curves.easeOut.transform(t / 0.4);
    if (t < 0.7) return 1.0 - Curves.easeIn.transform((t - 0.4) / 0.3);
    return 0.0;
  }
}