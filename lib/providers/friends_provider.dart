import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/friend_model.dart';
import '../models/chat_model.dart';
import 'auth_provider.dart';
import 'firestore_providers.dart';

// ── Map helpers ────────────────────────────────────────────────────────────

/// Converts a Firestore user profile map → [Friend].
Friend _friendFromMap(Map<String, dynamic> m) {
  final statusStr = m['status'] as String? ?? 'offline';
  final status = UserStatus.values.firstWhere(
    (s) => s.name == statusStr,
    orElse: () => UserStatus.offline,
  );
  final name   = m['displayName'] as String? ?? 'Player';
  final handle = m['handle'] as String? ?? '#unknown';
  return Friend(
    id:               m['uid'] as String? ?? m['id'] as String? ?? '',
    name:             name,
    handle:           handle.startsWith('#') ? handle : '#$handle',
    avatarInitial:    name.isNotEmpty ? name[0].toUpperCase() : '?',
    avatarColorIndex: m['avatarColorIndex'] as int? ?? 0,
    status:           status,
  );
}

/// Converts an incoming friend request Firestore map → [FriendRequest].
/// The map has: id, fromUid, fromDisplayName, fromHandle,
/// fromAvatarColorIndex, createdAt.
FriendRequest _requestFromMap(Map<String, dynamic> m) {
  final name   = m['fromDisplayName'] as String? ?? 'Player';
  final handle = m['fromHandle'] as String? ?? '#unknown';
  final fromUid = m['fromUid'] as String? ?? '';
  return FriendRequest(
    id: m['id'] as String? ?? '',
    friend: Friend(
      id:               fromUid,
      name:             name,
      handle:           handle.startsWith('#') ? handle : '#$handle',
      avatarInitial:    name.isNotEmpty ? name[0].toUpperCase() : '?',
      avatarColorIndex: m['fromAvatarColorIndex'] as int? ?? 0,
      status:           UserStatus.offline,
    ),
    direction: FriendRequestDirection.incoming,
    sentAt: m['createdAt'] is int
        ? DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int)
        : DateTime.now(),
  );
}

// ── Live friend list ───────────────────────────────────────────────────────

/// Stream of friends enriched with full profile data.
/// Converts raw Firestore maps → typed [Friend] objects.
final friendListProvider = StreamProvider<List<Friend>>((ref) {
  return ref.watch(friendsStreamProvider).when(
    data:    (maps) => Stream.value(maps.map(_friendFromMap).toList()),
    loading: () => const Stream.empty(),
    error:   (e, _) => Stream.error(e),
  );
});

// ── Live incoming requests ─────────────────────────────────────────────────

final friendRequestsProvider = StreamProvider<List<FriendRequest>>((ref) {
  return ref.watch(incomingRequestsStreamProvider).when(
    data:    (maps) => Stream.value(maps.map(_requestFromMap).toList()),
    loading: () => const Stream.empty(),
    error:   (e, _) => Stream.error(e),
  );
});

// ── Party members (local UI state only) ───────────────────────────────────
// Party membership is toggled locally while selecting friends to invite.
// It is persisted to RTDB only when the party is created.

final _partyMemberIdsProvider = StateProvider<Set<String>>((ref) => {});

final partyMembersProvider = Provider<List<Friend>>((ref) {
  final ids     = ref.watch(_partyMemberIdsProvider);
  final friends = ref.watch(friendListProvider).valueOrNull ?? [];
  return friends.where((f) => ids.contains(f.id)).toList();
});

void togglePartyMember(WidgetRef ref, String friendId) {
  final notifier = ref.read(_partyMemberIdsProvider.notifier);
  final ids = {...notifier.state};
  if (ids.contains(friendId)) {
    ids.remove(friendId);
  } else {
    ids.add(friendId);
  }
  notifier.state = ids;
}

/// Clears all party member selections. Called by [PartyNotifier.disband()].
void clearPartyMembers(Ref ref) {
  ref.read(_partyMemberIdsProvider.notifier).state = {};
}

// ── Active filter & search ─────────────────────────────────────────────────

final friendFilterProvider = StateProvider<FriendFilter>((ref) => FriendFilter.all);
final friendSearchQueryProvider = StateProvider<String>((ref) => '');

// ── Derived: filtered + searched ──────────────────────────────────────────

final filteredFriendsProvider = Provider<List<Friend>>((ref) {
  final friends = ref.watch(friendListProvider).valueOrNull ?? [];
  final filter  = ref.watch(friendFilterProvider);
  final query   = ref.watch(friendSearchQueryProvider).toLowerCase().trim();
  final partyIds = ref.watch(_partyMemberIdsProvider);

  return friends.map((f) {
    // Inject isPartyMember from local state
    return f.copyWith(isPartyMember: partyIds.contains(f.id));
  }).where((f) {
    final matchesFilter = switch (filter) {
      FriendFilter.all    => true,
      FriendFilter.inGame => f.status == UserStatus.inGame,
      FriendFilter.online => f.status == UserStatus.online,
      FriendFilter.idle   => f.status == UserStatus.idle,
    };
    final matchesSearch = query.isEmpty ||
        f.name.toLowerCase().contains(query) ||
        f.handle.toLowerCase().contains(query);
    return matchesFilter && matchesSearch;
  }).toList()
    ..sort(_statusSort);
});

int _statusSort(Friend a, Friend b) {
  const order = {
    UserStatus.inGame:  0,
    UserStatus.online:  1,
    UserStatus.idle:    2,
    UserStatus.offline: 3,
  };
  return (order[a.status] ?? 4).compareTo(order[b.status] ?? 4);
}

// ── Sections ───────────────────────────────────────────────────────────────

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

  bool get isEmpty =>
      inGame.isEmpty && online.isEmpty && idle.isEmpty && offline.isEmpty;
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

// ── Counts ─────────────────────────────────────────────────────────────────

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
  final friends = ref.watch(friendListProvider).valueOrNull ?? [];
  return FriendCounts(
    all:    friends.length,
    inGame: friends.where((f) => f.status == UserStatus.inGame).length,
    online: friends.where((f) => f.status == UserStatus.online).length,
    idle:   friends.where((f) => f.status == UserStatus.idle).length,
  );
});

// ── Add friend query ───────────────────────────────────────────────────────

final addFriendQueryProvider = StateProvider<String>((ref) => '');

// ── User search results ────────────────────────────────────────────────────
// Fires a Firestore prefix query whenever addFriendQueryProvider changes.
// Returns [] while the query is empty or loading.

final userSearchProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final query   = ref.watch(addFriendQueryProvider).trim();
  final myUid   = ref.watch(currentUidRequiredProvider);
  final service = ref.watch(firestoreServiceProvider);

  if (query.isEmpty) return [];
  return service.searchUsersByHandle(query, excludeUid: myUid);
});