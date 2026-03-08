import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../widgets/section_header.dart';

/// Three settings groups: Notifications, Privacy, Account.
/// Each row has a label, optional sublabel, and either a toggle or a chevron.
class SettingsSection extends ConsumerWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Notifications ─────────────────────────────────────────
        const SectionHeader(title: 'Notifications'),
        _SettingsGroup(
          children: [
            _ToggleRow(
              icon: Icons.notifications_outlined,
              label: 'Push Notifications',
              value: s.pushNotifications,
              onToggle: () => ref.read(settingsProvider.notifier).toggle('pushNotifications'),
            ),
            _ToggleRow(
              icon: Icons.person_add_outlined,
              label: 'Friend Requests',
              value: s.friendRequests,
              onToggle: () => ref.read(settingsProvider.notifier).toggle('friendRequests'),
            ),
            _ToggleRow(
              icon: Icons.sports_esports_outlined,
              label: 'Game Invites',
              value: s.gameInvites,
              onToggle: () => ref.read(settingsProvider.notifier).toggle('gameInvites'),
            ),
            _ToggleRow(
              icon: Icons.group_outlined,
              label: 'Group Messages',
              sublabel: 'Mentions only when muted',
              value: s.groupMessages,
              onToggle: () => ref.read(settingsProvider.notifier).toggle('groupMessages'),
            ),
            _ToggleRow(
              icon: Icons.volume_up_outlined,
              label: 'Sound Effects',
              value: s.soundEffects,
              onToggle: () => ref.read(settingsProvider.notifier).toggle('soundEffects'),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // ── Privacy ───────────────────────────────────────────────
        const SectionHeader(title: 'Privacy'),
        _SettingsGroup(
          children: [
            _ToggleRow(
              icon: Icons.visibility_outlined,
              label: 'Show Online Status',
              value: s.showOnlineStatus,
              onToggle: () => ref.read(settingsProvider.notifier).toggle('showOnlineStatus'),
            ),
            _ToggleRow(
              icon: Icons.sports_esports_rounded,
              label: 'Show Current Game',
              sublabel: 'Visible to friends',
              value: s.showCurrentGame,
              onToggle: () => ref.read(settingsProvider.notifier).toggle('showCurrentGame'),
            ),
            _ToggleRow(
              icon: Icons.person_add_alt_1_outlined,
              label: 'Allow Friend Requests',
              value: s.allowFriendRequests,
              onToggle: () => ref.read(settingsProvider.notifier).toggle('allowFriendRequests'),
            ),
            _ToggleRow(
              icon: Icons.emoji_events_outlined,
              label: 'Show Achievements',
              value: s.showAchievements,
              onToggle: () => ref.read(settingsProvider.notifier).toggle('showAchievements'),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // ── Display ───────────────────────────────────────────────
        const SectionHeader(title: 'Display'),
        _SettingsGroup(
          children: [
            _ToggleRow(
              icon: Icons.view_compact_outlined,
              label: 'Compact Mode',
              sublabel: 'Denser chat layout',
              value: s.compactMode,
              onToggle: () => ref.read(settingsProvider.notifier).toggle('compactMode'),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // ── Account ───────────────────────────────────────────────
        const SectionHeader(title: 'Account'),
        _SettingsGroup(
          children: [
            _ActionRow(
              icon: Icons.lock_outline_rounded,
              label: 'Change Password',
              onTap: () {},
            ),
            _ActionRow(
              icon: Icons.language_rounded,
              label: 'Language',
              trailing: 'English',
              onTap: () {},
            ),
            _ActionRow(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: () {},
            ),
            _ActionRow(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              color: AppColors.danger,
              onTap: () => _confirmSignOut(context, ref),
            ),
          ],
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SignOutSheet(onConfirm: () async {
        Navigator.pop(context); // close sheet first
        await ref.read(authActionProvider.notifier).signOut();
        // AuthGate in main.dart automatically routes to LoginScreen
        // once the auth stream emits null — no manual navigation needed.
      }),
    );
  }
}

// ── Sign-out confirmation sheet ────────────────────────────────────────────

class _SignOutSheet extends StatefulWidget {
  const _SignOutSheet({required this.onConfirm});
  final Future<void> Function() onConfirm;

  @override
  State<_SignOutSheet> createState() => _SignOutSheetState();
}

class _SignOutSheetState extends State<_SignOutSheet> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
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
          Text('Sign Out?',
              style: AppTextStyles.screenTitle.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            'You can sign back in at any time.',
            style: AppTextStyles.chatPreview
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Confirm button — shows spinner while signing out
          GestureDetector(
            onTap: _loading
                ? null
                : () async {
                    setState(() => _loading = true);
                    await widget.onConfirm();
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 46,
              decoration: BoxDecoration(
                color: _loading
                    ? AppColors.danger.withOpacity(0.6)
                    : AppColors.danger,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      'Sign Out',
                      style: AppTextStyles.chatName
                          .copyWith(color: Colors.white, fontSize: 15),
                    ),
            ),
          ),
          const SizedBox(height: 10),

          // Cancel
          GestureDetector(
            onTap: _loading ? null : () => Navigator.pop(context),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                'Cancel',
                style: AppTextStyles.chatName
                    .copyWith(color: AppColors.textSecondary, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings group container ───────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 0, indent: 50),
            children[i],
          ],
        ],
      ),
    );
  }
}

// ── Toggle row ─────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onToggle,
    this.sublabel,
  });

  final IconData icon;
  final String label;
  final String? sublabel;
  final bool value;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.chatName.copyWith(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                if (sublabel != null)
                  Text(sublabel!,
                      style: AppTextStyles.chatPreview.copyWith(
                          fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onToggle();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 26,
              decoration: BoxDecoration(
                color: value ? AppColors.accent : AppColors.bgCard,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: value ? AppColors.accent : AppColors.borderStrong,
                  width: 1.5,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    width: 18, height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action row (chevron) ───────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: c),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.chatName.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: c),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: AppTextStyles.chatPreview
                      .copyWith(fontSize: 13, color: AppColors.textMuted),
                ),
              if (trailing == null && color == null)
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}