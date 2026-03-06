import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/party_model.dart';
import '../../../providers/party_provider.dart';

/// Two-part game selection UI:
///  1. Horizontally scrollable game cards (icon + name)
///  2. Mode selector row that updates when game changes
class GamePickerSection extends ConsumerWidget {
  const GamePickerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final party = ref.watch(activePartyProvider);
    if (party == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text('Select Game', style: AppTextStyles.sectionLabel),
        ),

        // ── Game cards ───────────────────────────────────────────
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: gameOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final game = gameOptions[i];
              final isSelected = party.selectedGame.id == game.id;
              return _GameCard(
                game: game,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(activePartyProvider.notifier).selectGame(game);
                },
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // ── Mode selector ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: _ModeSelectorRow(
            modes: party.selectedGame.modes,
            selectedMode: party.selectedMode,
            onSelect: (mode) {
              HapticFeedback.selectionClick();
              ref.read(activePartyProvider.notifier).selectMode(mode);
            },
          ),
        ),
      ],
    );
  }
}

// ── Game card ──────────────────────────────────────────────────────────────

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.game,
    required this.isSelected,
    required this.onTap,
  });

  final GameOption game;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(game.gradientStart ?? 0xFF1a2040),
              Color(game.gradientEnd   ?? 0xFF0e1428),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(game.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 5),
            Text(
              game.name,
              style: AppTextStyles.chatTime.copyWith(
                fontSize: 10.5,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mode selector ──────────────────────────────────────────────────────────

class _ModeSelectorRow extends StatelessWidget {
  const _ModeSelectorRow({
    required this.modes,
    required this.selectedMode,
    required this.onSelect,
  });

  final List<String> modes;
  final String selectedMode;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mode', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: modes.map((mode) {
            final isSelected = mode == selectedMode;
            return GestureDetector(
              onTap: () => onSelect(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentSoft
                      : AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent.withOpacity(0.35)
                        : AppColors.border,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  mode,
                  style: AppTextStyles.sectionLabel.copyWith(
                    fontSize: 12,
                    letterSpacing: 0.1,
                    color: isSelected
                        ? AppColors.accentHover
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}