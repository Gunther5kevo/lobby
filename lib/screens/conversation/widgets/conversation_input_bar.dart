import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/conversation_provider.dart';

/// The full bottom input bar for the conversation screen.
///
/// States it handles:
///  1. Idle — attach button + text field + voice record button
///  2. Has text — send button replaces voice record button
///  3. Recording — slide-to-cancel UI replaces the field
///  4. Attachment sheet — slides up an options panel
class ConversationInputBar extends ConsumerStatefulWidget {
  const ConversationInputBar({
    super.key,
    required this.chatId,
    this.onSend,
  });

  final String chatId;
  final void Function(String text)? onSend;

  @override
  ConsumerState<ConversationInputBar> createState() =>
      _ConversationInputBarState();
}

class _ConversationInputBarState
    extends ConsumerState<ConversationInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    final hasText = value.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    ref.read(inputTextProvider.notifier).state = value;
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSend?.call(text);
    ref.read(messagesProvider(widget.chatId).notifier).sendText(text);
    _controller.clear();
    setState(() => _hasText = false);
    ref.read(inputTextProvider.notifier).state = '';
    HapticFeedback.lightImpact();
  }

  void _toggleAttachSheet() {
    HapticFeedback.lightImpact();
    final current = ref.read(attachSheetVisibleProvider);
    ref.read(attachSheetVisibleProvider.notifier).state = !current;
  }

  @override
  Widget build(BuildContext context) {
    final recordState = ref.watch(voiceRecordStateProvider);
    final isRecording = recordState != VoiceRecordState.idle;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Attach options panel
        _AttachPanel(),

        // Main input row
        Container(
          padding: EdgeInsets.fromLTRB(
            14, 10, 14,
            MediaQuery.of(context).padding.bottom + 10,
          ),
          decoration: const BoxDecoration(
            color: AppColors.bgSurface,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: isRecording
              ? _RecordingRow(chatId: widget.chatId)
              : _InputRow(
                  controller: _controller,
                  hasText: _hasText,
                  onTextChanged: _onTextChanged,
                  onSend: _sendMessage,
                  onToggleAttach: _toggleAttachSheet,
                  chatId: widget.chatId,
                ),
        ),
      ],
    );
  }
}

// ── Normal input row ───────────────────────────────────────────────────────

class _InputRow extends ConsumerWidget {
  const _InputRow({
    required this.controller,
    required this.hasText,
    required this.onTextChanged,
    required this.onSend,
    required this.onToggleAttach,
    required this.chatId,
  });

  final TextEditingController controller;
  final bool hasText;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onSend;
  final VoidCallback onToggleAttach;
  final String chatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Attach button
        _SmallIconBtn(
          icon: Icons.attach_file_rounded,
          onTap: onToggleAttach,
        ),

        const SizedBox(width: 9),

        // Text field
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 110),
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onTextChanged,
                    style: AppTextStyles.searchText.copyWith(fontSize: 14),
                    cursorColor: AppColors.accent,
                    cursorWidth: 1.5,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Message…',
                      hintStyle: AppTextStyles.searchHint,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.fromLTRB(14, 9, 4, 9),
                      isDense: true,
                    ),
                  ),
                ),
                // Emoji button inside field
                Padding(
                  padding: const EdgeInsets.only(right: 6, bottom: 6),
                  child: GestureDetector(
                    onTap: () {},
                    child: const Icon(
                      Icons.emoji_emotions_outlined,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 9),

        // Send / voice record button
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: hasText
              ? _SendButton(key: const ValueKey('send'), onTap: onSend)
              : _VoiceButton(key: const ValueKey('voice'), chatId: chatId),
        ),
      ],
    );
  }
}

// ── Recording row — shown while mic is held ────────────────────────────────

class _RecordingRow extends ConsumerWidget {
  const _RecordingRow({required this.chatId});
  final String chatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secs = ref.watch(recordingDurationProvider);
    final mm = (secs ~/ 60).toString().padLeft(2, '0');
    final ss = (secs % 60).toString().padLeft(2, '0');

    return Row(
      children: [
        // Cancel
        GestureDetector(
          onTap: () {
            ref.read(voiceRecordStateProvider.notifier).state =
                VoiceRecordState.idle;
          },
          child: const Icon(Icons.delete_outline_rounded,
              color: AppColors.danger, size: 24),
        ),

        const SizedBox(width: 12),

        // Waveform animation
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.fiber_manual_record_rounded,
                    color: AppColors.danger, size: 10),
                const SizedBox(width: 8),
                Text(
                  '$mm:$ss',
                  style: AppTextStyles.chatTime.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '← Slide to cancel',
                    style: AppTextStyles.chatPreview
                        .copyWith(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 9),

        // Lock icon
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
        ),
      ],
    );
  }
}

// ── Attachment options panel ───────────────────────────────────────────────

class _AttachPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(attachSheetVisibleProvider);

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: visible
          ? Container(
              color: AppColors.bgSurface,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AttachOption(
                    emoji: '🖼️',
                    label: 'Image',
                    onTap: () => ref
                        .read(attachSheetVisibleProvider.notifier)
                        .state = false,
                  ),
                  _AttachOption(
                    emoji: '🎬',
                    label: 'Clip',
                    onTap: () => ref
                        .read(attachSheetVisibleProvider.notifier)
                        .state = false,
                  ),
                  _AttachOption(
                    emoji: '📸',
                    label: 'Screenshot',
                    onTap: () => ref
                        .read(attachSheetVisibleProvider.notifier)
                        .state = false,
                  ),
                  _AttachOption(
                    emoji: '🎮',
                    label: 'Game Invite',
                    onTap: () => ref
                        .read(attachSheetVisibleProvider.notifier)
                        .state = false,
                  ),
                  _AttachOption(
                    emoji: '🎙️',
                    label: 'Voice Chat',
                    onTap: () => ref
                        .read(attachSheetVisibleProvider.notifier)
                        .state = false,
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _AttachOption extends StatelessWidget {
  const _AttachOption({
    required this.emoji,
    required this.label,
    required this.onTap,
  });
  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: AppTextStyles.chatTime.copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

// ── Small shared widgets ───────────────────────────────────────────────────

class _SmallIconBtn extends StatelessWidget {
  const _SmallIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
      ),
    );
  }
}

class _VoiceButton extends ConsumerWidget {
  const _VoiceButton({super.key, required this.chatId});
  final String chatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPressStart: (_) {
        HapticFeedback.mediumImpact();
        ref.read(voiceRecordStateProvider.notifier).state =
            VoiceRecordState.recording;
      },
      onLongPressEnd: (_) {
        ref.read(voiceRecordStateProvider.notifier).state =
            VoiceRecordState.idle;
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}