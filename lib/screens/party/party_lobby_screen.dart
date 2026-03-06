import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/party_model.dart';
import '../../providers/party_provider.dart';
import 'widgets/disband_confirmation.dart';
import 'widgets/game_picker_row.dart';
import 'widgets/party_header.dart';
import 'widgets/party_member_card.dart';
import 'widgets/voice_controls_bar.dart';

/// Full-screen party lobby modal.
///
/// Navigate to this using:
///   Navigator.of(context).push(PartyLobbyScreen.route());
///
/// It slides up from the bottom (modal style) and pops itself when
/// the party is disbanded.
class PartyLobbyScreen extends ConsumerWidget {
  const PartyLobbyScreen({super.key});

  static Route<void> route() {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => const PartyLobbyScreen(),
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 380),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final party = ref.watch(activePartyProvider);

    // Auto-pop if party is disbanded from outside
    ref.listen(activePartyProvider, (_, next) {
      if (next == null && context.mounted) {
        Navigator.of(context).maybePop();
      }
    });

    if (party == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            // ── Drag handle (modal feel) ──────────────────────────
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Scrollable body ───────────────────────────────────
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: PartyHeader(
                      party: party,
                      onDisband: () => _handleDisband(context, ref),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // ── Members section ─────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Row(
                        children: [
                          Text(
                            'Members',
                            style: AppTextStyles.sectionLabel,
                          ),
                          const SizedBox(width: 8),
                          // Ready count badge
                          _ReadyCountBadge(
                            ready: party.readyCount,
                            total: party.members.length,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: party.members.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final member = party.members[i];
                        return PartyMemberCard(
                          member: member,
                          isMe: member.friendId == 'me',
                        );
                      },
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // ── Game picker ─────────────────────────────────
                  const SliverToBoxAdapter(child: GamePickerSection()),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // ── Voice controls ──────────────────────────────
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: VoiceControlsBar(),
                    ),
                  ),

                  // Bottom padding for the CTA button
                  const SliverPadding(
                    padding: EdgeInsets.only(bottom: 120),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── Floating queue CTA ──────────────────────────────────────
      bottomNavigationBar: _QueueCTA(party: party),
    );
  }

  Future<void> _handleDisband(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDisbandConfirmation(context);
    if (confirmed == true) {
      ref.read(activePartyProvider.notifier).disband();
      // Pop handled by the listener above
    }
  }
}

// ── Ready count badge ──────────────────────────────────────────────────────

class _ReadyCountBadge extends StatelessWidget {
  const _ReadyCountBadge({required this.ready, required this.total});
  final int ready;
  final int total;

  @override
  Widget build(BuildContext context) {
    final allReady = ready == total;
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: allReady
            ? AppColors.success.withOpacity(0.12)
            : AppColors.bgCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: allReady
              ? AppColors.success.withOpacity(0.25)
              : AppColors.border,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$ready / $total ready',
        style: AppTextStyles.badge.copyWith(
          fontSize: 10,
          color: allReady ? AppColors.success : AppColors.textMuted,
        ),
      ),
    );
  }
}

// ── Queue CTA button ───────────────────────────────────────────────────────

class _QueueCTA extends ConsumerWidget {
  const _QueueCTA({required this.party});
  final Party party;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsed = ref.watch(queueElapsedProvider);
    final isInQueue = party.status == PartyStatus.inQueue;
    final isInGame  = party.status == PartyStatus.inGame;
    final canQueue  = party.allReady;

    // Format elapsed time for queue timer
    final mm = (elapsed.inSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 12, 20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status message above button
          if (!canQueue && !isInQueue && !isInGame)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'Waiting for all members to ready up…',
                    style: AppTextStyles.chatPreview.copyWith(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

          if (isInGame)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Match found! Loading game…',
                    style: AppTextStyles.chatPreview.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // Main button
          GestureDetector(
            onTap: () {
              if (isInQueue) {
                HapticFeedback.mediumImpact();
                ref.read(activePartyProvider.notifier).cancelQueue();
              } else if (canQueue && !isInGame) {
                HapticFeedback.heavyImpact();
                ref.read(activePartyProvider.notifier).startQueue();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 52,
              decoration: BoxDecoration(
                color: isInGame
                    ? AppColors.success
                    : isInQueue
                        ? AppColors.warning.withOpacity(0.9)
                        : canQueue
                            ? AppColors.accent
                            : AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: canQueue || isInQueue || isInGame
                      ? Colors.transparent
                      : AppColors.border,
                ),
                boxShadow: canQueue || isInQueue
                    ? [
                        BoxShadow(
                          color: (isInQueue ? AppColors.warning : AppColors.accent)
                              .withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isInGame
                        ? Icons.sports_esports_rounded
                        : isInQueue
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                    color: canQueue || isInQueue || isInGame
                        ? Colors.white
                        : AppColors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isInGame
                        ? 'In Game'
                        : isInQueue
                            ? 'In Queue  $mm:$ss  ·  Cancel'
                            : 'Start Queue',
                    style: AppTextStyles.chatName.copyWith(
                      color: canQueue || isInQueue || isInGame
                          ? Colors.white
                          : AppColors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}