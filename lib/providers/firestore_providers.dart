import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';

// ── Service providers ──────────────────────────────────────────────────────

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

// ── User profile stream ────────────────────────────────────────────────────

/// Live stream of the signed-in user's Firestore profile.
/// Rebuilds any widget watching it whenever the profile doc changes.
final myProfileStreamProvider =
    StreamProvider<Map<String, dynamic>?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).profileStream(uid);
});

/// One-shot fetch of any user profile by UID (for friend tiles, etc.).
final userProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, uid) async {
  return ref.watch(firestoreServiceProvider).getProfile(uid);
});

// ── Friends ────────────────────────────────────────────────────────────────

/// Live stream of the current user's accepted friends.
/// Each item is a Firestore doc from /users/{myUid}/friends/{theirUid},
/// then enriched with the friend's full profile.
final friendsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid      = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();
  final service  = ref.watch(firestoreServiceProvider);

  // First get the friend uid list, then resolve each profile
  return service.friendsStream(uid).asyncMap((friendDocs) async {
    final profiles = await Future.wait(
      friendDocs.map((doc) => service.getProfile(doc['uid'] as String)),
    );
    // Merge: add presence/activity info if you want (from RTDB) later
    return profiles.whereType<Map<String, dynamic>>().toList();
  });
});

// ── Friend requests ────────────────────────────────────────────────────────

final incomingRequestsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid     = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();
  final service = ref.watch(firestoreServiceProvider);
  return service.incomingRequestsStream(uid);
});

// ── Friends actions ────────────────────────────────────────────────────────

class FriendsActionNotifier extends StateNotifier<AsyncValue<void>> {
  FriendsActionNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;
  FirestoreService get _fs => _ref.read(firestoreServiceProvider);
  String get _myUid => _ref.read(currentUidProvider)!;

  Future<void> sendRequest(String toUid) async {
    await _fs.sendFriendRequest(fromUid: _myUid, toUid: toUid);
  }

  Future<void> acceptRequest(String requestId, String theirUid) async {
    await _fs.acceptFriendRequest(
      requestId: requestId,
      myUid:     _myUid,
      theirUid:  theirUid,
    );
  }

  Future<void> declineRequest(String requestId) async {
    await _fs.declineFriendRequest(requestId);
  }

  Future<void> removeFriend(String theirUid) async {
    await _fs.removeFriend(_myUid, theirUid);
  }
}

final friendsActionProvider =
    StateNotifierProvider<FriendsActionNotifier, AsyncValue<void>>((ref) {
  return FriendsActionNotifier(ref);
});

// ── Groups ─────────────────────────────────────────────────────────────────

/// Live stream of groups the current user has joined.
final myGroupsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid     = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();
  final service = ref.watch(firestoreServiceProvider);
  return service.myGroupsStream(uid);
});

/// Live stream of channels inside a specific group.
final channelsStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, groupId) {
  return ref.watch(firestoreServiceProvider).channelsStream(groupId);
});

// ── DM chats ───────────────────────────────────────────────────────────────

final dmChatsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid     = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();
  final service = ref.watch(firestoreServiceProvider);
  return service.dmChatsStream(uid);
});

// ── Connected games ────────────────────────────────────────────────────────

final connectedGamesStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid     = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();
  final service = ref.watch(firestoreServiceProvider);
  return service.connectedGamesStream(uid);
});

// ── Profile update actions ─────────────────────────────────────────────────

class ProfileActionNotifier extends StateNotifier<AsyncValue<void>> {
  ProfileActionNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;
  FirestoreService get _fs      => _ref.read(firestoreServiceProvider);
  StorageService   get _storage => _ref.read(storageServiceProvider);
  String           get _myUid   => _ref.read(currentUidProvider)!;

  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fs.updateProfile(_myUid, data),
    );
  }

  Future<void> saveConnectedGame(Map<String, dynamic> gameData) async {
    await _fs.saveConnectedGame(_myUid, gameData);
  }
}

final profileActionProvider =
    StateNotifierProvider<ProfileActionNotifier, AsyncValue<void>>((ref) {
  return ProfileActionNotifier(ref);
});