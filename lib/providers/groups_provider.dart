import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_model.dart';

// ── Group list ─────────────────────────────────────────────────────────────

final groupListProvider =
    StateNotifierProvider<GroupListNotifier, List<Group>>((ref) {
  return GroupListNotifier();
});

class GroupListNotifier extends StateNotifier<List<Group>> {
  GroupListNotifier() : super(seedGroups);

  void joinGroup(Group group) {
    if (state.any((g) => g.id == group.id)) return;
    state = [...state, group];
  }

  void leaveGroup(String groupId) {
    state = state.where((g) => g.id != groupId).toList();
    // Clear active group if it was this one
  }

  void toggleMute(String groupId) {
    state = [
      for (final g in state)
        if (g.id == groupId) g.copyWith(isMuted: !g.isMuted) else g,
    ];
  }

  void markChannelRead(String groupId, String channelId) {
    state = [
      for (final g in state)
        if (g.id == groupId)
          g.copyWith(
            channels: [
              for (final c in g.channels)
                if (c.id == channelId) c.copyWith(unreadCount: 0) else c,
            ],
          )
        else
          g,
    ];
  }

  void setActiveChannel(String groupId, String channelId) {
    state = [
      for (final g in state)
        if (g.id == groupId)
          g.copyWith(activeChannelId: channelId)
        else
          g,
    ];
    markChannelRead(groupId, channelId);
  }
}

// ── Active (expanded) group ────────────────────────────────────────────────
// When a group row is tapped it expands to show its channels inline.

final activeGroupIdProvider = StateProvider<String?>((ref) => null);

final activeGroupProvider = Provider<Group?>((ref) {
  final id = ref.watch(activeGroupIdProvider);
  if (id == null) return null;
  return ref
      .watch(groupListProvider)
      .where((g) => g.id == id)
      .firstOrNull;
});

// ── Group search ───────────────────────────────────────────────────────────

final groupSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredGroupsProvider = Provider<List<Group>>((ref) {
  final groups = ref.watch(groupListProvider);
  final query  = ref.watch(groupSearchQueryProvider).toLowerCase().trim();
  if (query.isEmpty) return groups;
  return groups
      .where((g) =>
          g.name.toLowerCase().contains(query) ||
          g.tags.any((t) => t.toLowerCase().contains(query)))
      .toList();
});

// ── Total group unread count ───────────────────────────────────────────────

final totalGroupUnreadProvider = Provider<int>((ref) {
  return ref
      .watch(groupListProvider)
      .where((g) => !g.isMuted)
      .fold(0, (sum, g) => sum + g.totalUnread);
});