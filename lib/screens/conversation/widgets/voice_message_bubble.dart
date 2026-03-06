import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/message_model.dart';

/// Voice message bubble.
/// Shows a play/pause button, an animated waveform of normalised bar heights,
/// and the duration label.
///
/// [playedFraction] (0.0–1.0) controls how many bars are "played" (accent colour).
/// In a real app this would be driven by an audio player stream.
class VoiceMessageBubble extends StatefulWidget {
  const VoiceMessageBubble({
    super.key,
    required this.voiceNote,
    required this.isMine,
  });

  final VoiceNote voiceNote;
  final bool isMine;

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  bool _isPlaying = false;

  void _togglePlay() => setState(() => _isPlaying = !_isPlaying);

  @override
  Widget build(BuildContext context) {
    final note = widget.voiceNote;
    final bg = widget.isMine ? AppColors.bubbleSent : AppColors.bubbleReceived;
    final borderColor = widget.isMine
        ? const Color(0x334F80FF)
        : AppColors.border;

    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft:     const Radius.circular(14),
          topRight:    const Radius.circular(14),
          bottomLeft:  Radius.circular(widget.isMine ? 14 : 4),
          bottomRight: Radius.circular(widget.isMine ? 4 : 14),
        ),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play / pause button
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Waveform
          Expanded(
            child: _Waveform(
              bars: note.waveformData,
              playedFraction: note.playedFraction,
            ),
          ),

          const SizedBox(width: 8),

          // Duration
          Text(
            note.durationLabel,
            style: AppTextStyles.chatTime.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Waveform bars ─────────────────────────────────────────────────────────

class _Waveform extends StatelessWidget {
  const _Waveform({
    required this.bars,
    required this.playedFraction,
  });

  final List<double> bars;
  final double playedFraction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(bars.length, (i) {
          final played = i / bars.length < playedFraction;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: FractionallySizedBox(
                heightFactor: bars[i].clamp(0.1, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: played ? AppColors.accent : AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}