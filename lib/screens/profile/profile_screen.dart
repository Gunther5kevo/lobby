import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/firestore_providers.dart';
import 'widgets/achievements_section.dart';
import 'widgets/connected_games_section.dart';
import 'widgets/edit_profile_sheet.dart';
import 'widgets/profile_header.dart';
import 'widgets/settings_section.dart';
import 'widgets/stats_section.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        bottom: false,
        child: profileAsync.when(
          data: (profile) => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Top spacing ──────────────────────────────────────
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Profile header card ──────────────────────────────
              SliverToBoxAdapter(
                child: ProfileHeader(
                  profile: profile,
                  onEdit: () => _showEditSheet(context, profile),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 6)),

              // ── Game stats ───────────────────────────────────────
              SliverToBoxAdapter(
                child: StatsSection(gameStats: profile.gameStats),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 6)),

              // ── Achievements ─────────────────────────────────────
              SliverToBoxAdapter(
                child: AchievementsSection(achievements: profile.achievements),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 6)),

              // ── Connected games ──────────────────────────────────
              SliverToBoxAdapter(
                child: ConnectedGamesSection(games: profile.connectedGames),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 6)),

              // ── Settings ─────────────────────────────────────────
              const SliverToBoxAdapter(child: SettingsSection()),

              // ── Nav bar padding ──────────────────────────────────
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error loading profile: $error'),
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditProfileSheet(profile: profile),
    );
  }
}