import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/chat_model.dart';
import '../../../models/profile_model.dart';
import '../../../providers/profile_provider.dart';
import '../../../widgets/guild_avatar.dart';
import '../../../widgets/status_dot.dart';

/// Bottom sheet for editing display name, handle, bio, and status.
class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({super.key, required this.profile});
  final UserProfile profile;

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _handleCtrl;
  late final TextEditingController _bioCtrl;
  late UserStatus _status;

  @override
  void initState() {
    super.initState();
    _nameCtrl   = TextEditingController(text: widget.profile.displayName);
    _handleCtrl = TextEditingController(text: widget.profile.handle);
    _bioCtrl    = TextEditingController(text: widget.profile.bio);
    _status     = widget.profile.status;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _handleCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _save() {
    HapticFeedback.lightImpact();
    ref.read(profileActionProvider.notifier).updateProfile(
          displayName: _nameCtrl.text.trim(),
          handle: _handleCtrl.text.trim(),
          bio: _bioCtrl.text.trim(),
          status: _status,
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          0, 0, 0, MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Edit Profile',
                      style:
                          AppTextStyles.screenTitle.copyWith(fontSize: 18)),
                  const Spacer(),
                  // Save button
                  GestureDetector(
                    onTap: _save,
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Save',
                        style: AppTextStyles.sectionLabel.copyWith(
                          color: Colors.white,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Avatar preview (non-editable in demo)
            Center(
              child: Stack(
                children: [
                  GuildAvatar(
                    initial: widget.profile.avatarInitial,
                    colorIndex: widget.profile.avatarColorIndex,
                    size: 72,
                    status: _status,
                    dotBorderColor: AppColors.bgElevated,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.bgElevated, width: 2),
                      ),
                      child: const Icon(Icons.photo_camera_outlined,
                          size: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Form fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Display Name'),
                  const SizedBox(height: 6),
                  _TextField(controller: _nameCtrl, hint: 'Your name'),

                  const SizedBox(height: 14),

                  const _FieldLabel('Handle'),
                  const SizedBox(height: 6),
                  _TextField(
                      controller: _handleCtrl,
                      hint: '#handle',
                      prefix: ''),

                  const SizedBox(height: 14),

                  const _FieldLabel('Bio'),
                  const SizedBox(height: 6),
                  _TextField(
                    controller: _bioCtrl,
                    hint: 'Tell people about yourself…',
                    maxLines: 3,
                  ),

                  const SizedBox(height: 16),

                  // Status picker
                  const _FieldLabel('Status'),
                  const SizedBox(height: 8),
                  _StatusPicker(
                    selected: _status,
                    onSelect: (s) => setState(() => _status = s),
                  ),
                ],
              ),
            ),

            SizedBox(
                height: MediaQuery.of(context).padding.bottom + 24),
          ],
        ),
      ),
    );
  }
}

// ── Status picker ──────────────────────────────────────────────────────────

class _StatusPicker extends StatelessWidget {
  const _StatusPicker({required this.selected, required this.onSelect});
  final UserStatus selected;
  final ValueChanged<UserStatus> onSelect;

  @override
  Widget build(BuildContext context) {
    const options = [
      (UserStatus.online,  'Online'),
      (UserStatus.idle,    'Idle'),
      (UserStatus.offline, 'Invisible'),
    ];

    return Row(
      children: options.map((opt) {
        final (status, label) = opt;
        final isActive = selected == status;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(status),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(right: 8),
              height: 40,
              decoration: BoxDecoration(
                color: isActive ? AppColors.accentSoft : AppColors.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? AppColors.accent.withOpacity(0.3)
                      : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StatusDot(status: status, size: 8),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppTextStyles.sectionLabel.copyWith(
                      fontSize: 12,
                      color: isActive
                          ? AppColors.accentHover
                          : AppColors.textSecondary,
                      letterSpacing: 0.05,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Form field helpers ─────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.sectionLabel);
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    this.prefix,
    this.maxLines = 1,
  });
  final TextEditingController controller;
  final String hint;
  final String? prefix;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: AppTextStyles.searchText.copyWith(fontSize: 14),
        cursorColor: AppColors.accent,
        cursorWidth: 1.5,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.searchHint,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}