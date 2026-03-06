import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import './chats/chats_screen.dart';
import './friends/friends_screen.dart';
import './groups/groups_screen.dart';
import './profile/profile_screen.dart';

/// Root scaffold. Hosts the [GuildBottomNavBar] and swaps
/// between top-level screens based on [navIndexProvider].
///
/// Screens other than Chats are stubs — we'll build them
/// in the next steps of this series.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _screens = [
    ChatsScreen(),
    FriendsScreen(),
    GroupsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navIndexProvider);

    return Scaffold(
      body: IndexedStack(
        // IndexedStack keeps all screens alive — important for
        // maintaining scroll position when switching tabs.
        index: index,
        children: _screens,
      ),
      bottomNavigationBar: const GuildBottomNavBar(),
    );
  }
}

/// Placeholder for screens we haven't built yet.
class _StubScreen extends StatelessWidget {
  const _StubScreen({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF555E7A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}