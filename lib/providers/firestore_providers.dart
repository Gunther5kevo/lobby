import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_model.dart';
import '../models/chat_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';

// ── Service singletons ─────────────────────────────────────────────────────

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

// ── Typed UserProfile stream ───────────────────────────────────────────────

/// The current user's full [UserProfile], assembled from:
///   - /users/{uid}                   (main doc stream)
///   - /users/{uid}/connectedGames    (sub-collection stream)
///   - friends count derived from friends stream length
///   - groups count derived from groups stream length
///
/// This is the single provider the profile screen watches.
/// It emits a new value whenever any of those three sources change.
final myProfileProvider = StreamProvider<UserProfile>((ref) async* {
  final uid     = ref.watch(currentUidRequiredProvider);
  final service = ref.watch(firestoreServiceProvider);

  await for (final doc in service.profileStream(uid)) {
    if (doc == null) continue;

    // Fetch connected games snapshot (one-shot per profile doc change)
    final gameDocs = await service
        .connectedGamesStream(uid)
        .first
        .timeout(const Duration(seconds: 3), onTimeout: () => []);

    final connectedGames = gameDocs
        .map((m) => ConnectedGame.fromMap(m))
        .toList();

    // Count friends and groups for the stats row
    final friendCount = await service
        .friendsStream(uid)
        .first
        .timeout(const Duration(seconds: 3), onTimeout: () => [])
        .then((list) => list.length);

    final groupCount = await service
        .myGroupsStream(uid)
        .first
        .timeout(const Duration(seconds: 3), onTimeout: () => [])
        .then((list) => list.length);

    yield UserProfile.fromFirestore(
      doc,
      connectedGames: connectedGames,
    ).copyWith(
      totalFriends: friendCount,
      totalGroups:  groupCount,
    );
  }
});

/// Typed stream of just the connected games sub-collection.
/// Used by ConnectedGamesSection to stay live after the profile is loaded.
final connectedGamesTypedProvider = StreamProvider<List<ConnectedGame>>((ref) {
  final uid     = ref.watch(currentUidRequiredProvider);
  final service = ref.watch(firestoreServiceProvider);
  return service
      .connectedGamesStream(uid)
      .map((list) => list.map(ConnectedGame.fromMap).toList());
});

// ── Raw map streams (kept for non-profile use cases) ──────────────────────

final myProfileStreamProvider =
    StreamProvider<Map<String, dynamic>?>((ref) {
  final uid = ref.watch(currentUidRequiredProvider);
  return ref.watch(firestoreServiceProvider).profileStream(uid);
});

final userProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, uid) async {
  return ref.watch(firestoreServiceProvider).getProfile(uid);
});

// ── Profile update actions ─────────────────────────────────────────────────

class ProfileSaveState {
  const ProfileSaveState({this.isSaving = false, this.error});
  final bool    isSaving;
  final String? error;
  ProfileSaveState copyWith({bool? isSaving, String? error}) =>
      ProfileSaveState(isSaving: isSaving ?? this.isSaving, error: error);
}

class ProfileActionNotifier extends StateNotifier<ProfileSaveState> {
  ProfileActionNotifier(this._ref) : super(const ProfileSaveState());

  final Ref _ref;
  FirestoreService get _fs      => _ref.read(firestoreServiceProvider);
  StorageService   get _storage => _ref.read(storageServiceProvider);
  String           get _myUid   => _ref.read(currentUidRequiredProvider);

  /// Update editable text fields + status.
  Future<bool> updateProfile({
    required String displayName,
    required String handle,
    required String bio,
    required UserStatus status,
  }) async {
    state = const ProfileSaveState(isSaving: true);
    try {
      await _fs.updateProfile(_myUid, {
        'displayName': displayName,
        'handle':      handle,
        'bio':         bio,
        'status':      status.name,
      });
      state = const ProfileSaveState();
      return true;
    } catch (e) {
      state = ProfileSaveState(error: e.toString());
      return false;
    }
  }

  /// Upload avatar image and persist the URL to Firestore.
  Future<String?> uploadAvatar(File file, {void Function(double)? onProgress}) async {
    state = const ProfileSaveState(isSaving: true);
    try {
      final url = await _storage.uploadAvatar(
        uid: _myUid, file: file, onProgress: onProgress);
      await _fs.updateProfile(_myUid, {'avatarUrl': url});
      state = const ProfileSaveState();
      return url;
    } catch (e) {
      state = ProfileSaveState(error: e.toString());
      return null;
    }
  }

  /// Toggle a game's connected state (writes back to sub-collection).
  Future<void> toggleGameConnection(ConnectedGame game) async {
    final updated = game.copyWith(isConnected: !game.isConnected);
    await _fs.saveConnectedGame(_myUid, updated.toMap());
  }

  /// Save a newly connected game (from OAuth or detection).
  Future<void> saveConnectedGame(ConnectedGame game) async {
    await _fs.saveConnectedGame(_myUid, game.toMap());
  }

  void clearError() => state = state.copyWith(error: null);
}

final profileActionProvider =
    StateNotifierProvider<ProfileActionNotifier, ProfileSaveState>((ref) {
  return ProfileActionNotifier(ref);
});

// ── Friends ────────────────────────────────────────────────────────────────

final friendsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid     = ref.watch(currentUidRequiredProvider);
  final service = ref.watch(firestoreServiceProvider);
  return service.friendsStream(uid).asyncMap((friendDocs) async {
    final profiles = await Future.wait(
        friendDocs.map((doc) => service.getProfile(doc['uid'] as String)));
    return profiles.whereType<Map<String, dynamic>>().toList();
  });
});

final incomingRequestsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid     = ref.watch(currentUidRequiredProvider);
  final service = ref.watch(firestoreServiceProvider);
  return service.incomingRequestsStream(uid);
});

class FriendsActionNotifier extends StateNotifier<AsyncValue<void>> {
  FriendsActionNotifier(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;
  FirestoreService get _fs    => _ref.read(firestoreServiceProvider);
  String           get _myUid => _ref.read(currentUidRequiredProvider);

  Future<void> sendRequest(String toUid) async =>
      _fs.sendFriendRequest(fromUid: _myUid, toUid: toUid);

  Future<void> acceptRequest(String requestId, String theirUid) async =>
      _fs.acceptFriendRequest(
          requestId: requestId, myUid: _myUid, theirUid: theirUid);

  Future<void> declineRequest(String requestId) async =>
      _fs.declineFriendRequest(requestId);

  Future<void> removeFriend(String theirUid) async =>
      _fs.removeFriend(_myUid, theirUid);
}

final friendsActionProvider =
    StateNotifierProvider<FriendsActionNotifier, AsyncValue<void>>((ref) =>
        FriendsActionNotifier(ref));

// ── Groups ─────────────────────────────────────────────────────────────────

final myGroupsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid     = ref.watch(currentUidRequiredProvider);
  final service = ref.watch(firestoreServiceProvider);
  return service.myGroupsStream(uid);
});

final channelsStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, groupId) =>
        ref.watch(firestoreServiceProvider).channelsStream(groupId));

// ── DM chats ───────────────────────────────────────────────────────────────

final dmChatsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid     = ref.watch(currentUidRequiredProvider);
  final service = ref.watch(firestoreServiceProvider);
  return service.dmChatsStream(uid);
});