import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/friend_model.dart';
import '../models/chat_model.dart';

// ── Friend list ────────────────────────────────────────────────────────────

final friendListProvider =
    StateNotifierProvider<FriendListNotifier, List<Friend>>((ref) {
  return FriendListNotifier();
});

class FriendListNotifier extends StateNotifier<List<Friend>> {
  FriendListNotifier() : super(seedFriends);

  void togglePartyMember(String friendId) {
    state = [
      for (final f in state)
        if (f.id == friendId)
          f.copyWith(isPartyMember: !f.isPartyMember)
        else
          f,
    ];
  }

  void addFriend(Friend friend) {
    if (state.any((f) => f.id == friend.id)) return;
    state = [...state, friend];
  }

  void removeFriend(String friendId) {
    state = state.where((f) => f.id != friendId).toList();
  }
}

// ── Friend requests ────────────────────────────────────────────────────────

final friendRequestsProvider =
    StateNotifierProvider<FriendRequestsNotifier, List<FriendRequest>>((ref) {
  return FriendRequestsNotifier(ref);
});

class FriendRequestsNotifier extends StateNotifier<List<FriendRequest>> {
  FriendRequestsNotifier(this._ref) : super(seedRequests);

  final Ref _ref;

  void accept(String requestId) {
    final req = state.firstWhere((r) => r.id == requestId);
    _ref.read(friendListProvider.notifier).addFriend(req.friend);
    state = state.where((r) => r.id != requestId).toList();
  }

  void decline(String requestId) {
    state = state.where((r) => r.id != requestId).toList();
  }
}

// ── Active filter ──────────────────────────────────────────────────────────

final friendFilterProvider = StateProvider<FriendFilter>((ref) => FriendFilter.all);

// ── Search query ───────────────────────────────────────────────────────────

final friendSearchQueryProvider = StateProvider<String>((ref) => '');

// ── Derived: filtered + searched friends ──────────────────────────────────

final filteredFriendsProvider = Provider<List<Friend>>((ref) {
  final friends = ref.watch(friendListProvider);
  final filter  = ref.watch(friendFilterProvider);
  final query   = ref.watch(friendSearchQueryProvider).toLowerCase().trim();

  return friends.where((f) {
    // Filter by status
    final matchesFilter = switch (filter) {
      FriendFilter.all    => true,
      FriendFilter.inGame => f.status == UserStatus.inGame,
      FriendFilter.online => f.status == UserStatus.online,
      FriendFilter.idle   => f.status == UserStatus.idle,
    };

    // Filter by search query
    final matchesSearch = query.isEmpty ||
        f.name.toLowerCase().contains(query) ||
        f.handle.toLowerCase().contains(query);

    return matchesFilter && matchesSearch;
  }).toList()
    ..sort(_statusSort);
});

// Sort: inGame → online → idle → offline
int _statusSort(Friend a, Friend b) {
  const order = {
    UserStatus.inGame:  0,
    UserStatus.online:  1,
    UserStatus.idle:    2,
    UserStatus.offline: 3,
  };
  return (order[a.status] ?? 4).compareTo(order[b.status] ?? 4);
}

// ── Derived: section-grouped friends ──────────────────────────────────────

class FriendSections {
  const FriendSections({
    required this.inGame,
    required this.online,
    required this.idle,
    required this.offline,
  });
  final List<Friend> inGame;
  final List<Friend> online;
  final List<Friend> idle;
  final List<Friend> offline;

  bool get isEmpty => inGame.isEmpty && online.isEmpty && idle.isEmpty && offline.isEmpty;
}

final friendSectionsProvider = Provider<FriendSections>((ref) {
  final friends = ref.watch(filteredFriendsProvider);
  return FriendSections(
    inGame:  friends.where((f) => f.status == UserStatus.inGame).toList(),
    online:  friends.where((f) => f.status == UserStatus.online).toList(),
    idle:    friends.where((f) => f.status == UserStatus.idle).toList(),
    offline: friends.where((f) => f.status == UserStatus.offline).toList(),
  );
});

// ── Derived: counts for filter chips ──────────────────────────────────────

class FriendCounts {
  const FriendCounts({
    required this.all,
    required this.inGame,
    required this.online,
    required this.idle,
  });
  final int all;
  final int inGame;
  final int online;
  final int idle;
}

final friendCountsProvider = Provider<FriendCounts>((ref) {
  final friends = ref.watch(friendListProvider);
  return FriendCounts(
    all:    friends.length,
    inGame: friends.where((f) => f.status == UserStatus.inGame).length,
    online: friends.where((f) => f.status == UserStatus.online).length,
    idle:   friends.where((f) => f.status == UserStatus.idle).length,
  );
});

// ── Party members ──────────────────────────────────────────────────────────

final partyMembersProvider = Provider<List<Friend>>((ref) {
  return ref.watch(friendListProvider).where((f) => f.isPartyMember).toList();
});

// ── Add friend search (separate query from list search) ───────────────────

final addFriendQueryProvider = StateProvider<String>((ref) => '');